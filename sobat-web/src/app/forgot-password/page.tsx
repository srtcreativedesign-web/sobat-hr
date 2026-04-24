'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Image from 'next/image';
import Link from 'next/link';
import { motion, AnimatePresence } from 'motion/react';
import apiClient from '@/lib/api-client';

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
  }, []);

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

  const handleOtpChange = (element: any, idx: number) => {
    if (isNaN(element.value)) return false;

    setOtp([...otp.map((d, index) => (index === idx ? element.value : d))]);

    // Focus next input
    if (element.nextSibling && element.value) {
      element.nextSibling.focus();
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
                <motion.div
                  key="step1"
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                >
                  <h2 className="text-3xl font-bold text-white mb-2">Reset Password</h2>
                  <p className="text-white/60 mb-8">Masukkan Nomor WhatsApp Anda yang terdaftar pada sistem SOBA HR.</p>
                  
                  <form onSubmit={handleRequestOTP} className="space-y-6">
                    <div className="space-y-2">
                      <label className="text-sm font-medium text-white/90 ml-1">Nomor WhatsApp</label>
                      <div className="relative group">
                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                          <svg className="h-5 w-5 text-white/50 group-focus-within:text-[#60A5FA] transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                          </svg>
                        </div>
                        <input
                          type="text"
                          value={phone}
                          onChange={(e) => setPhone(e.target.value.replace(/[^0-9]/g, ''))}
                          className="w-full pl-12 pr-4 py-4 bg-white/5 border border-white/10 rounded-xl text-white placeholder-white/30 focus:outline-none focus:border-[#60A5FA] focus:bg-white/10 focus:ring-1 focus:ring-[#60A5FA] transition-all duration-300"
                          placeholder="081234567890"
                          required
                        />
                      </div>
                    </div>

                    <button
                      type="submit"
                      disabled={loading || !phone}
                      className="w-full py-4 bg-[#60A5FA] text-white font-bold text-lg rounded-xl shadow-lg hover:bg-[#1C3ECA] hover:shadow-blue-500/30 transition-all duration-300 disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center"
                    >
                      {loading ? (
                        <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                      ) : 'Kirim OTP'}
                    </button>
                  </form>
                </motion.div>
              )}

              {/* STEP 2: VERIFY OTP */}
              {step === 2 && (
                <motion.div
                  key="step2"
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                  className="flex flex-col items-center"
                >
                  <h2 className="text-3xl font-bold text-white mb-2 text-center">Verifikasi OTP</h2>
                  <p className="text-white/60 mb-8 text-center text-sm">
                    Kode 6 digit telah dikirimkan ke WhatsApp Anda ({phone}).<br/>Masukkan kode tersebut di bawah ini.
                  </p>

                  <form onSubmit={handleVerifyOTP} className="w-full space-y-8">
                    <div className="flex justify-center gap-2 sm:gap-3">
                      {otp.map((data, index) => {
                        return (
                          <input
                            className="w-10 h-12 sm:w-12 sm:h-14 bg-white/5 border border-white/20 rounded-lg text-white text-center text-xl font-bold focus:bg-white/10 focus:border-[#60A5FA] focus:ring-1 focus:ring-[#60A5FA] focus:outline-none transition-all"
                            type="text"
                            name="otp"
                            maxLength={1}
                            key={index}
                            value={data}
                            onChange={(e) => handleOtpChange(e.target, index)}
                            onFocus={e => e.target.select()}
                          />
                        );
                      })}
                    </div>

                    <div className="text-center">
                      {countdown > 0 ? (
                        <p className="text-white/50 text-sm">Kirim ulang kode dalam <span className="text-[#60A5FA] font-bold">00:{countdown.toString().padStart(2, '0')}</span></p>
                      ) : (
                        <button
                          type="button"
                          onClick={handleRequestOTP}
                          disabled={loading}
                          className="text-[#60A5FA] text-sm font-semibold hover:text-white transition-colors"
                        >
                          Kirim Ulang Kode OTP
                        </button>
                      )}
                    </div>

                    <button
                      type="submit"
                      disabled={loading || otp.join('').length !== 6}
                      className="w-full py-4 bg-[#60A5FA] text-white font-bold text-lg rounded-xl shadow-lg hover:bg-[#1C3ECA] hover:shadow-blue-500/30 transition-all duration-300 disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center"
                    >
                      {loading ? (
                        <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                      ) : 'Verifikasi OTP'}
                    </button>
                  </form>
                </motion.div>
              )}

              {/* STEP 3: RESET PASSWORD */}
              {step === 3 && (
                <motion.div
                  key="step3"
                  initial={{ opacity: 0, x: 20 }}
                  animate={{ opacity: 1, x: 0 }}
                  exit={{ opacity: 0, x: -20 }}
                >
                  <h2 className="text-3xl font-bold text-white mb-2">Ubah Password</h2>
                  <p className="text-white/60 mb-8">Silakan buat password baru Anda yang kuat dan mudah diingat.</p>

                  <form onSubmit={handleResetPassword} className="space-y-6">
                    <div className="space-y-2">
                      <label className="text-sm font-medium text-white/90 ml-1">Password Baru</label>
                      <div className="relative group">
                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                          <svg className="h-5 w-5 text-white/50 group-focus-within:text-[#60A5FA] transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                          </svg>
                        </div>
                        <input
                          type={showPassword ? "text" : "password"}
                          value={password}
                          onChange={(e) => setPassword(e.target.value)}
                          className="w-full pl-12 pr-12 py-4 bg-white/5 border border-white/10 rounded-xl text-white placeholder-white/30 focus:outline-none focus:border-[#60A5FA] focus:bg-white/10 focus:ring-1 focus:ring-[#60A5FA] transition-all duration-300"
                          placeholder="••••••••"
                          required
                        />
                        <button
                          type="button"
                          onClick={() => setShowPassword(!showPassword)}
                          className="absolute inset-y-0 right-0 pr-4 flex items-center text-white/50 hover:text-white transition-colors"
                        >
                          {showPassword ? (
                            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                          ) : (
                            <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.59 3.59m0 0A9.953 9.953 0 0112 5c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0L21 21" /></svg>
                          )}
                        </button>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <label className="text-sm font-medium text-white/90 ml-1">Konfirmasi Password Baru</label>
                      <div className="relative group">
                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                          <svg className="h-5 w-5 text-white/50 group-focus-within:text-[#60A5FA] transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                          </svg>
                        </div>
                        <input
                          type={showPassword ? "text" : "password"}
                          value={passwordConfirm}
                          onChange={(e) => setPasswordConfirm(e.target.value)}
                          className="w-full pl-12 pr-4 py-4 bg-white/5 border border-white/10 rounded-xl text-white placeholder-white/30 focus:outline-none focus:border-[#60A5FA] focus:bg-white/10 focus:ring-1 focus:ring-[#60A5FA] transition-all duration-300"
                          placeholder="••••••••"
                          required
                        />
                      </div>
                    </div>

                    <button
                      type="submit"
                      disabled={loading || !password || !passwordConfirm}
                      className="w-full py-4 bg-[#60A5FA] text-white font-bold text-lg rounded-xl shadow-lg hover:bg-[#1C3ECA] hover:shadow-blue-500/30 transition-all duration-300 disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center"
                    >
                      {loading ? (
                        <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                        </svg>
                      ) : 'Simpan Password Baru'}
                    </button>
                  </form>
                </motion.div>
              )}

              {/* STEP 4: SUCCESS */}
              {step === 4 && (
                <motion.div
                  key="step4"
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  className="flex flex-col items-center py-6 text-center"
                >
                  <div className="w-20 h-20 bg-green-500/20 text-green-400 rounded-full flex items-center justify-center mb-6 border border-green-500/30">
                    <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                  </div>
                  <h2 className="text-3xl font-bold text-white mb-2">Berhasil!</h2>
                  <p className="text-white/70 mb-8">Password Anda telah berhasil diperbarui. Silakan login kembali dengan password baru Anda.</p>
                  
                  <Link 
                    href="/login"
                    className="w-full py-4 bg-white/10 border border-white/20 text-white font-bold text-lg rounded-xl shadow-lg hover:bg-white/20 transition-all duration-300 flex items-center justify-center"
                  >
                    Kembali ke halaman Login
                  </Link>
                </motion.div>
              )}
            </AnimatePresence>

            {/* Back to Login Anchor for Steps 1-3 */}
            {step < 4 && (
              <div className="mt-8 text-center">
                <Link href="/login" className="text-white/60 text-sm font-semibold hover:text-[#60A5FA] transition-colors flex items-center justify-center gap-1">
                  <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
                  </svg>
                  Kembali ke Login
                </Link>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
