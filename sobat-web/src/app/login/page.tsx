'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/store/auth-store';

import LiquidEther from '@/components/LiquidEther';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const { login } = useAuthStore();
  const [error, setError] = useState('');

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      await login(email, password);

      // Smart Redirect based on Role
      const user = useAuthStore.getState().user;
      const roleName = typeof user?.role === 'string' ? user.role : (user?.role as any)?.name;

      if (roleName === 'staff') {
        router.push('/attendance');
      } else {
        router.push('/dashboard');
      }
    } catch (err: any) {
      setError(err.message || 'Login failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen relative overflow-hidden flex items-center justify-center p-4 bg-white">
      {/* Liquid Ether Background */}
      <div style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', zIndex: 0 }}>
        <LiquidEther
          colors={['#5227FF', '#FF9FFC', '#B19EEF']}
          mouseForce={20}
          cursorSize={100}
          isViscous
          viscous={30}
          iterationsViscous={32}
          iterationsPoisson={32}
          resolution={0.5}
          isBounce={false}
          autoDemo
          autoSpeed={0.5}
          autoIntensity={2.2}
          takeoverDuration={0.25}
          autoResumeDelay={3000}
          autoRampDuration={0.6}
          color0="#1cd48d"
          color1="#3fc6b6"
          color2="#10c19e"
        />
      </div>

      {/* Glass Card */}
      <div className="relative z-10 w-full max-w-md bg-white/40 backdrop-blur-xl border border-white/60 rounded-3xl p-8 shadow-xl animate-fade-in-up">

        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-[#462e37] mb-2">Welcome Back</h1>
          <p className="text-[#462e37]/70">Sign in to access SOBAT HR</p>
        </div>

        {error && (
          <div className="mb-6 p-4 rounded-xl bg-red-500/20 border border-red-500/50 text-red-200 text-sm flex items-center gap-2 animate-fade-in-up">
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            {error}
          </div>
        )}

        <form onSubmit={handleLogin} className="space-y-6">
          <div className="space-y-2">
            <label className="text-sm font-semibold text-[#462e37] ml-1">Email Address</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-5 py-4 bg-white/60 border border-white/40 rounded-xl text-[#462e37] placeholder-[#462e37]/40 focus:outline-none focus:border-[#462e37] focus:ring-1 focus:ring-[#462e37] transition-all duration-300"
              placeholder="admin@sobat.co.id"
              required
            />
          </div>

          <div className="space-y-2">
            <label className="text-sm font-semibold text-[#462e37] ml-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              className="w-full px-5 py-4 bg-white/60 border border-white/40 rounded-xl text-[#462e37] placeholder-[#462e37]/40 focus:outline-none focus:border-[#462e37] focus:ring-1 focus:ring-[#462e37] transition-all duration-300"
              placeholder="••••••••"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-4 mt-4 bg-[#462e37] text-[#a9eae2] font-bold text-lg rounded-xl shadow-lg hover:shadow-xl hover:scale-[1.02] active:scale-[0.98] transition-all duration-300 disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center"
          >
            {loading ? (
              <svg className="animate-spin h-5 w-5 text-[#0d2618]" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            ) : (
              'Sign In'
            )}
          </button>
        </form>

        <div className="mt-8 text-center text-sm text-[#462e37]/70">
          <Link href="/" className="hover:text-[#462e37] transition-colors font-semibold">
            ← Back to Home
          </Link>
        </div>
      </div>
    </div>
  );
}
