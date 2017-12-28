import conf, json, time, sys
import asyncio, urllib.parse
import logging

class Server:
    writer = None
    client_info = {}
    CLIENT_INFO_SRV_ID = 0
    CLIENT_INFO_LAT = 1
    CLIENT_INFO_LNG = 2
    CLIENT_INFO_TIME = 3
    CLIENT_INFO_TIME_DIFF = 4

    def __init__(self, event_loop, server_name):
        self.loop = event_loop
        self.server = server_name
        logging.basicConfig(filename='{}.log'.format(self.server), level=logging.DEBUG)
        logging.info("Server {} started\n".format(self.server))

    ## Write a string to a client
    # For handleWHATSAT(), I don't want to close the writer after sending an AT message since I need to write json msg to client after that
    # Thus close_writer_after argument is needed
    async def write_to_client(self, writer, msg, close_writer_after=True):
        assert writer != None
        writer.write(msg.encode())
        await writer.drain()
        logging.info("Wrote to client: {}\n".format(msg))
        if close_writer_after:
            writer.close()

    ## Cache client info got from client or another server
    def update_client_info(self, server_id, client_id, location, client_time, time_diff):
        # Skip old client info
        if client_id in self.client_info and float(self.client_info[client_id][self.CLIENT_INFO_TIME]) >= float(client_time):
            return
        # Separete latitude and longtitude from location
        lat, lng, i = [], [], 1
        for temp in location[i:]:
            if temp == '+' or temp == '-':
                break
            i += 1
        lat, lng = location[:i], location[i:]
        info = [server_id, lat, lng, client_time, time_diff]
        self.client_info[client_id] = info

    ## Send client info to one other server
    async def send_update(self, servers_got_update, target_server, client, location, client_time):
        target_port = conf.SRV_PORTS[target_server]
        reader, writer = await asyncio.open_connection("localhost", target_port, ssl=False)
        server_list = servers_got_update if self.server in servers_got_update.split(conf.SRV_DELIMITER) else (servers_got_update + conf.SRV_DELIMITER + self.server)
        await self.sendAT(writer, server_list, client, location, client_time)
        logging.info("Talked successfully to server {}\n".format(target_server))

    ## Propagate received client info to target servers
    async def propagate(self, servers_got_update, client, location, client_time):
        servers_got_update_list = servers_got_update.split(conf.SRV_DELIMITER)
        servers_to_propagate = [srv for srv in conf.SRV_KNOWS[self.server] if srv not in servers_got_update_list]
        for server in servers_to_propagate:
            task = self.loop.create_task(self.send_update(servers_got_update, server, client, location, client_time))
            # Try to talk to one server
            try:
                logging.info("Trying to talk to server {}\n".format(server))
                await task
            # Talk to next server if this this server can't be talked to
            except Exception as e:
                logging.info("Failed talking to server {0}: {1}\n".format(server, e))
                task.cancel()

    ## Send and AT message to client or another server
    async def sendAT(self, writer, server, client, location, client_time, close_writer_after=True):
        reply = "AT {0} {1} {2} {3} {4}\n".format(server, self.client_info[client][self.CLIENT_INFO_TIME_DIFF], client, location, client_time)
        await self.write_to_client(writer, reply, close_writer_after)

    ## Process IAMAT message     
    async def handleIAMAT(self, args):
        time_diff = time.time() - float(args[2])
        time_diff_str = "+" + str(time_diff) if time_diff >= 0 else str(time_diff)        
        self.update_client_info(self.server, args[0], args[1], args[2], time_diff_str)
        await self.sendAT(self.writer, self.server, args[0], args[1], args[2])
        asyncio.ensure_future(self.propagate(self.server, args[0], args[1], args[2]))

    ## Process AT message
    async def handleAT(self, args):
        servers_got_update = args[0].split(conf.SRV_DELIMITER)   
        self.update_client_info(servers_got_update[0], args[2], args[3], args[4], args[1])
        asyncio.ensure_future(self.propagate(args[0], args[2], args[3], args[4]))
    
    ## Process WHATSAT message
    async def handleWHATSAT(self, args):
        # Parse client info from args
        client = args[0]
        try:
            assert client in self.client_info
        except AssertionError:
            logging.info("No location info found for client {}\n".format(client))
            await self.write_to_client(self.writer, "**No location info found for client '{}'**\n".format(client))
        client_last_seen_server = self.client_info[client][self.CLIENT_INFO_SRV_ID]
        client_lat = self.client_info[client][self.CLIENT_INFO_LAT]
        client_lng = self.client_info[client][self.CLIENT_INFO_LNG]
        client_time = self.client_info[client][self.CLIENT_INFO_TIME]
        # Send AT msg
        location = client_lat + client_lng
        await self.sendAT(self.writer, client_last_seen_server, client, location, client_time, False)
        # Formatting request
        radius = float(args[1])*1000 # from km to m
        url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location={0},{1}&radius={2}&key={3}".format(client_lat, client_lng, radius, conf.API_KEY)
        url_parsed = urllib.parse.urlsplit(url)
        # Send GET request to Google Place
        reader, writer = await asyncio.open_connection(url_parsed.netloc, 443, ssl=True)
        get = "GET {0}?{1} HTTP/1.1\r\nHost: {2}\r\nContent-Type: text/plain; charset=utf-8\r\nConnection: close\r\n\r\n\r\n".format(url_parsed.path, url_parsed.query, url_parsed.hostname)
        writer.write(get.encode())
        await writer.drain()
        data = ''
        # Ignore the header
        header = await reader.readuntil(b"\r\n\r\n")
        # Read the actual json
        while True:
            line = await reader.readline()
            if not line:
                break
            data += line.decode()
        writer.close()

        # Apply limit and send back results to the client
        jdata = json.loads(data)
        output = jdata["results"]
        limit = int(args[2])
        output = output[:limit]
        jdata["results"] = output
        await self.write_to_client(self.writer, json.dumps(jdata, indent=3)+"\r\n\r\n")    

    ## Run this server
    async def run_server(self, reader, writer):
        self.writer = writer
        raw = await reader.readline()
        logging.info("Received from client: {}\n".format(raw.decode()))
        args = raw.decode().split()
        if len(args) == 0 or args[0] not in conf.COMMANDS or len(args) != conf.COMMANDS[args[0]]:
            await self.write_to_client(self.writer, "? {}".format(raw.decode()))
        elif args[0] == "IAMAT":
            if '+' not in args[2] or '-' not in args[2]:
                await self.write_to_client(self.writer, "? {}".format(raw.decode()))
            else:
                await self.handleIAMAT(args[1:])
        elif args[0] == "AT":
            await self.handleAT(args[1:])
        elif args[0] == "WHATSAT":
            await self.handleWHATSAT(args[1:])
        else:
            await self.write_to_client(self.writer, "**Unknown error occured!**\n")

def print_usage():
    print("Usage: " + sys.argv[0] + " server_name\nserver_name = 'Alford' | 'Ball' | 'Hamilton' | 'Holiday' | 'Welsh'")

def main():
    # Argument checking
    if len(sys.argv) != 2:
        print_usage()
        exit(1)
    server_name = sys.argv[1]
    if server_name not in conf.SRV_PORTS:
        print_usage()
        exit(1)
    port_num = conf.SRV_PORTS[server_name]

    # Create the server and main event loop
    event_loop = asyncio.get_event_loop()
    my_server = Server(event_loop, server_name)
    coro = asyncio.start_server(my_server.run_server, "localhost", port_num)
    server = event_loop.run_until_complete(coro)
    try:
        event_loop.run_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.close()
        event_loop.run_until_complete(server.wait_closed())
        event_loop.close()

if __name__ == "__main__":
    main()


