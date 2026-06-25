import React from 'react';
import { motion } from 'motion/react';

interface VerifyOtpFormProps {
    phone: string;
    otp: string[];
    setOtp: (otp: string[]) => void;
    countdown: number;
    loading: boolean;
    onSubmit: (e: React.FormEvent) => void;
    onRequestOtp: (e: React.FormEvent) => void;
}

export default function VerifyOtpForm({
    phone,
    otp,
    setOtp,
    countdown,
    loading,
    onSubmit,
    onRequestOtp
}: VerifyOtpFormProps) {
    const handleOtpChange = (element: any, idx: number) => {
        if (isNaN(element.value)) return false;

        const newOtp = [...otp];
        newOtp[idx] = element.value;
        setOtp(newOtp);

        if (element.nextSibling && element.value) {
            element.nextSibling.focus();
        }
    };

    return (
        <motion.div
            key="step2"
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -20 }}
            className="flex flex-col items-center"
        >
            <h2 className="text-3xl font-bold text-white mb-2 text-center">Verifikasi OTP</h2>
            <p className="text-white/60 mb-8 text-center text-sm">
                Kode 6 digit telah dikirimkan ke WhatsApp Anda ({phone}).<br />Masukkan kode tersebut di bawah ini.
            </p>

            <form onSubmit={onSubmit} className="w-full space-y-8">
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
                            onClick={onRequestOtp}
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
    );
}
