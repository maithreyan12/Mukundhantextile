import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('Test Supabase Real OTP Config', () async {
    final file = File('env_file');
    expect(file.existsSync(), isTrue, reason: 'env_file not found');
    
    final lines = file.readAsLinesSync();
    String url = '';
    String anonKey = '';
    for (var line in lines) {
      if (line.startsWith('SUPABASE_URL=')) {
        url = line.split('SUPABASE_URL=')[1].trim();
      }
      if (line.startsWith('SUPABASE_ANON_KEY=')) {
        anonKey = line.split('SUPABASE_ANON_KEY=')[1].trim();
      }
    }

    print('Supabase URL: $url');
    expect(url.isNotEmpty, isTrue);
    expect(anonKey.isNotEmpty, isTrue);

    final client = SupabaseClient(
      url,
      anonKey,
      authOptions: const AuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );

    print('--- Testing Mobile SMS OTP ---');
    try {
      // Trying to send SMS OTP to a test phone number
      await client.auth.signInWithOtp(
        phone: '+919342706675',
      );
      print('✅ SUCCESS: SMS OTP request sent successfully without errors.');
    } catch (e) {
      print('❌ FAILED: SMS OTP error: $e');
    }

    print('--- Testing Email Sign In OTP ---');
    try {
      // Trying to send Email OTP
      await client.auth.signInWithOtp(
        email: 'maithreyan2006@gmail.com',
      );
      print('✅ SUCCESS: Email OTP request sent successfully without errors.');
    } catch (e) {
      print('❌ FAILED: Email OTP error: $e');
    }
  });
}
