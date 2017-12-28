# Google Place API
API_KEY = "AIzaSyCwbN7Je97pmzb9I4Rb4Nj3MMNdqejM4j0"

# Command and length
COMMANDS = {'IAMAT': 4, 'AT': 6, 'WHATSAT': 4}

# Server
SRV_DELIMITER = '-'
SRV_PORTS = {'Alford': 12345, 'Ball': 12346, 'Hamilton': 12347, 'Holiday': 12348, 'Welsh': 12349}
SRV_KNOWS = {
    'Alford': ['Hamilton', 'Welsh'],
    'Ball': ['Holiday', 'Welsh'],
    'Hamilton': ['Alford', 'Holiday'],
    'Holiday': ['Ball', 'Hamilton'],
    'Welsh': ['Alford', 'Holiday']
}