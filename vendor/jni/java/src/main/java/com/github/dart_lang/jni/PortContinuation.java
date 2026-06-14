package com.github.dart_lang.jni;

import kotlin.coroutines.Continuation;
import kotlin.coroutines.CoroutineContext;
import kotlinx.coroutines.Dispatchers;

public class PortContinuation<T> implements Continuation<T> {
  static {
    System.loadLibrary("dartjni");
  }

  private final long port;

  public PortContinuation(long port) {
    this.port = port;
  }

  @Override
  public CoroutineContext getContext() {
    return (CoroutineContext) Dispatchers.getIO();
  }

  @Override
  public void resumeWith(Object o) {
    _resumeWith(port, o);
  }

  private native void _resumeWith(long port, Object result);
}
