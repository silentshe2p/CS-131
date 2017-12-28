import java.util.concurrent.atomic.AtomicIntegerArray;

class GetNSetState implements State {
    private java.util.concurrent.atomic.AtomicIntegerArray aia;
    private byte maxval;

    private void copyFromByteArr (byte[] v) {
        aia = new AtomicIntegerArray(v.length);
        int i;
        for (i = 0; i < v.length; i++) {
            aia.set(i, v[i]);
        }
    }

    GetNSetState (byte[] v) {
        copyFromByteArr(v);
        maxval = 127;
    }

    GetNSetState (byte[] v, byte m) {
        copyFromByteArr(v);
        maxval = m;
    }

    public int size() { return aia.length(); }

    public byte[] current() {
        int length = aia.length();
        byte[] v = new byte[length];
        int i;
        for (i = 0; i < length; i++) {
            v[i] = (byte) aia.get(i);
        }
        return v;
    }

    public boolean swap (int i, int j) {
        int ival = aia.get(i);
        int jval = aia.get(j);
        if (ival <= 0 || jval >= maxval) {
            return false;
        }
        aia.set(i, ival - 1);
        aia.set(j, jval + 1);
        return true;
    }
}