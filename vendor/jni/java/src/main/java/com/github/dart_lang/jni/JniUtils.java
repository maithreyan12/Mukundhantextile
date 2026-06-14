package com.github.dart_lang.jni;

public class JniUtils {
  static {
    System.loadLibrary("dartjni");
  }

  public static native Object fromReferenceAddress(long address);
}
