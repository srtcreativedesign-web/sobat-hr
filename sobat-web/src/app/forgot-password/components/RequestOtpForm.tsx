import React from 'react';
import { motion } from 'motion/react';

interface RequestOtpFormProps {
    phone: string;
    setPhone: (phone: string) => void;
    loading: boolean;
    onSubmit: (e: React.FormEvent) => void;
}

export default function RequestOtpForm({ phone, setPhone, loading, onSubmit }: RequestOtpFormProps) {
    return (
        <motion.div
            key="step1"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
        >
            <h2 className="text-3xl font-bold text-white mb-2">Reset Password</h2>
            <p className="text-white/60 mb-8">Masukkan Nomor WhatsApp Anda yang terdaftar pada sistem SOBA HR.</p>
            
            <form onSubmit={onSubmit} className="space-y-6">
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
    );
}
