'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { motion, AnimatePresence } from 'motion/react';
import apiClient from '@/lib/api-client';

import RequestOtpForm from './components/RequestOtpForm';
import VerifyOtpForm from './components/VerifyOtpForm';
import ResetPasswordForm from './components/ResetPasswordForm';

export default function ForgotPasswordPage() {
  const router = useRouter();
  
  // Step Management: 1 = Input Phone, 2 = Input OTP, 3 = New Password, 4 = Success
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  // Form Data
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState(['', '', '', '', '', '']);
  const [resetToken, setResetToken] = useState('');
  const [password, setPassword] = useState('');
  const [passwordConfirm, setPasswordConfirm] = useState('');

  // UI States
  const [showPassword, setShowPassword] = useState(false);
  const [countdown, setCountdown] = useState(0);

  const [index, setIndex] = useState(0);
  const words = ["MANAGE YOUR TEAM", "SIMPLIFY PAYROLL", "TRACK ATTENDANCE", "EMPOWER GROWTH"];

  useEffect(() => {
    const interval = setInterval(() => {
      setIndex((prev) => (prev + 1) % words.length);
    }, 4000);
    return () => clearInterval(interval);
  }, [words.length]);

  // Timer Countdown logic
  useEffect(() => {
    if (countdown > 0) {
      const timerId = setTimeout(() => setCountdown(countdown - 1), 1000);
      return () => clearTimeout(timerId);
    }
  }, [countdown]);

  const handleRequestOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      await apiClient.post('/forgot-password/request-otp', { phone_number: phone });
      setStep(2);
      setCountdown(60); // 60 seconds cooldown
    } catch (err: any) {
      setError(err.response?.data?.message || 'Nomor WhatsApp tidak terdaftar atau sistem sedang sibuk.');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyOTP = async (e: React.FormEvent) => {
    e.preventDefault();
    const otpCode = otp.join('');
    if (otpCode.length !== 6) {
      setError('Mohon lengkapi 6 digit kode OTP');
      return;
    }

    setLoading(true);
    setError('');

    try {
      const response = await apiClient.post('/forgot-password/verify-otp', {
        phone_number: phone,
        otp_code: otpCode
      });
      
      setResetToken(response.data.reset_token);
      setStep(3);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Kode OTP tidak valid atau sudah kedaluwarsa.');
    } finally {
      setLoading(false);
    }
  };

  const handleResetPassword = async (e: React.FormEvent) => {
    e.preventDefault();
    if (password !== passwordConfirm) {
      setError('Konfirmasi password tidak cocok.');
      return;
    }

    if (password.length < 6) {
      setError('Password minimal terdiri dari 6 karakter.');
      return;
    }

    setLoading(true);
    setError('');

    try {
      await apiClient.post('/forgot-password/reset', {
        reset_token: resetToken,
        password: password,
        password_confirmation: passwordConfirm
      });
      
      setStep(4);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Gagal mengubah password. Silakan coba kembali.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen relative overflow-hidden flex font-sans">
      {/* Background Image */}
      <div className="absolute inset-0 z-0">
        <Image
          src="/assets/login.jpg"
          alt="Office Background"
          fill
          className="object-cover"
          priority
        />
        {/* Dark Overlay */}
        <div className="absolute inset-0 bg-black/40" />
      </div>

      <div className="container relative z-10 mx-auto px-6 py-12 flex flex-col lg:flex-row items-center justify-between h-screen">
        {/* Left Side: Branding & Text */}
        <div className="w-full lg:w-1/2 flex flex-col text-white mb-12 lg:mb-0">
          {/* Logo */}
          <div className="flex items-center gap-3 mb-8">
            <div className="bg-white p-2 rounded-xl">
              <Image src="/logo/favicon.png" width={32} height={32} alt="Logo" className="object-contain" />
            </div>
            <span className="text-xl font-bold tracking-widest">SOBAT HR</span>
          </div>

          <h1 className="text-5xl lg:text-7xl font-black leading-none mb-6 tracking-tight">
            CONNECT<br />
            COLLABORATE<br />
            SUCCEED
          </h1>

          <div className="h-8 overflow-hidden relative">
            <AnimatePresence mode="wait">
              <motion.p
                key={index}
                initial={{ y: 20, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                exit={{ y: -20, opacity: 0 }}
                transition={{ duration: 0.5 }}
                className="text-lg font-medium tracking-[0.2em] text-white/80 absolute"
              >
                {words[index]}
              </motion.p>
            </AnimatePresence>
          </div>
        </div>

        {/* Right Side: Forms */}
        <div className="w-full lg:w-[480px]">
          <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-3xl p-8 lg:p-12 shadow-2xl relative overflow-hidden">
            
            {error && (
              <div className="mb-6 p-4 rounded-xl bg-red-500/20 border border-red-500/30 text-red-200 text-sm flex items-center gap-2">
                <svg className="w-5 h-5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {error}
              </div>
            )}

            <AnimatePresence mode="wait">
              {/* STEP 1: REQUEST OTP */}
              {step === 1 && (
                <RequestOtpForm 
                    phone={phone} 
                    setPhone={setPhone} 
                    loading={loading} 
                    onSubmit={handleRequestOTP} 
                />
              )}

              {/* STEP 2: VERIFY OTP */}
              {step === 2 && (
                <VerifyOtpForm 
                    phone={phone}
                    otp={otp}
                    setOtp={setOtp}
                    countdown={countdown}
                    loading={loading}
                    onSubmit={handleVerifyOTP}
                    onRequestOtp={handleRequestOTP}
                />
              )}

              {/* STEP 3: RESET PASSWORD */}
              {step === 3 && (
                <ResetPasswordForm 
                    password={password}
                    setPassword={setPassword}
                    passwordConfirm={passwordConfirm}
                    setPasswordConfirm={setPasswordConfirm}
                    showPassword={showPassword}
                    setShowPassword={setShowPassword}
                    loading={loading}
                    onSubmit={handleResetPassword}
                />
              )}

              {/* STEP 4: SUCCESS */}
              {step === 4 && (
                <motion.div
                  key="step4"
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="flex flex-col items-center text-center"
                >
                  <div className="w-20 h-20 bg-green-500/20 rounded-full flex items-center justify-center mb-6">
                    <svg className="w-10 h-10 text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                  <h2 className="text-3xl font-bold text-white mb-2">Berhasil!</h2>
                  <p className="text-white/60 mb-8">Password Anda telah berhasil diubah. Silakan login kembali dengan password baru Anda.</p>
                  
                  <Link 
                    href="/login"
                    className="w-full py-4 bg-[#89b4e1] text-white font-bold text-lg rounded-xl shadow-lg hover:bg-[#419cc3] transition-all duration-300 flex items-center justify-center"
                  >
                    Kembali ke Login
                  </Link>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Back to Login Link */}
            {step === 1 && (
              <div className="mt-8 text-center">
                <Link href="/login" className="text-sm text-white/60 hover:text-white transition-colors flex items-center justify-center gap-2">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                  </svg>
                  Kembali ke Halaman Login
                </Link>
              </div>
            )}
            
          </div>
        </div>
      </div>
    </div>
  );
}
