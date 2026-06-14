package com.github.dart_lang.jni;

import java.lang.ref.PhantomReference;
import java.lang.ref.ReferenceQueue;

class PortCleaner {
  static {
    System.loadLibrary("dartjni");
  }

  private final ReferenceQueue<Object> queue = new ReferenceQueue<>();
  private final PortPhantom list = new PortPhantom();

  private class PortPhantom extends PhantomReference<Object> {
    final long port;

    PortPhantom prev = this, next = this;

    PortPhantom(Object referent, long port) {
      super(referent, queue);
      this.port = port;
      insert();
    }

    PortPhantom() {
      super(null, null);
      this.port = 0;
    }

    void insert() {
      synchronized (list) {
        prev = list;
        next = list.next;
        next.prev = this;
        list.next = this;
      }
    }

    private void remove() {
      synchronized (list) {
        next.prev = prev;
        prev.next = next;
        prev = this;
        next = this;
      }
    }
  }

  PortCleaner() {
    Thread thread = new Thread(() -> {
      while (true) {
        try {
          PortPhantom portPhantom = (PortPhantom) queue.remove();
          portPhantom.remove();
          if (portPhantom.port != 0) {
            clean(portPhantom.port);
          }
        } catch (Throwable e) {
        }
      }
    }, "PortCleaner");
    thread.setDaemon(true);
    thread.start();
  }

  void register(Object obj, long port) {
    new PortPhantom(obj, port);
  }

  private static native void clean(long port);
}
