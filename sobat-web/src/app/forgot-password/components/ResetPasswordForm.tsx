import React from 'react';
import { motion } from 'motion/react';

interface ResetPasswordFormProps {
    password: string;
    setPassword: (password: string) => void;
    passwordConfirm: string;
    setPasswordConfirm: (password: string) => void;
    showPassword: boolean;
    setShowPassword: (show: boolean) => void;
    loading: boolean;
    onSubmit: (e: React.FormEvent) => void;
}

export default function ResetPasswordForm({
    password,
    setPassword,
    passwordConfirm,
    setPasswordConfirm,
    showPassword,
    setShowPassword,
    loading,
    onSubmit
}: ResetPasswordFormProps) {
    return (
        <motion.div
            key="step3"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
        >
            <h2 className="text-3xl font-bold text-white mb-2">Ubah Password</h2>
            <p className="text-white/60 mb-8">Silakan buat password baru Anda yang kuat dan mudah diingat.</p>

            <form onSubmit={onSubmit} className="space-y-6">
                <div className="space-y-2">
                    <label className="text-sm font-medium text-white/90 ml-1">Password Baru</label>
                    <div className="relative group">
                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                            <svg className="h-5 w-5 text-white/50 group-focus-within:text-[#89b4e1] transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                            </svg>
                        </div>
                        <input
                            type={showPassword ? "text" : "password"}
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            className="w-full pl-12 pr-12 py-4 bg-white/5 border border-white/10 rounded-xl text-white placeholder-white/30 focus:outline-none focus:border-[#89b4e1] focus:bg-white/10 focus:ring-1 focus:ring-[#89b4e1] transition-all duration-300"
                            placeholder="••••••••"
                            required
                        />
                        <button
                            type="button"
                            onClick={() => setShowPassword(!showPassword)}
                            className="absolute inset-y-0 right-0 pr-4 flex items-center text-white/50 hover:text-white transition-colors"
                        >
                            {showPassword ? (
                                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.29 3.29m0 0a10.05 10.05 0 015.71-1.583c4.478 0 8.268 2.943 9.543 7a10.025 10.025 0 01-4.132 5.411m0 0l-3.29-3.29" /></svg>
                            ) : (
                                <svg className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                            )}
                        </button>
                    </div>
                </div>

                <div className="space-y-2">
                    <label className="text-sm font-medium text-white/90 ml-1">Konfirmasi Password</label>
                    <div className="relative group">
                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                            <svg className="h-5 w-5 text-white/50 group-focus-within:text-[#89b4e1] transition-colors" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                            </svg>
                        </div>
                        <input
                            type={showPassword ? "text" : "password"}
                            value={passwordConfirm}
                            onChange={(e) => setPasswordConfirm(e.target.value)}
                            className="w-full pl-12 pr-12 py-4 bg-white/5 border border-white/10 rounded-xl text-white placeholder-white/30 focus:outline-none focus:border-[#89b4e1] focus:bg-white/10 focus:ring-1 focus:ring-[#89b4e1] transition-all duration-300"
                            placeholder="••••••••"
                            required
                        />
                    </div>
                </div>

                <button
                    type="submit"
                    disabled={loading || !password || !passwordConfirm}
                    className="w-full py-4 bg-[#89b4e1] text-white font-bold text-lg rounded-xl shadow-lg hover:bg-[#419cc3] hover:shadow-blue-500/30 transition-all duration-300 disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center"
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
    );
}
