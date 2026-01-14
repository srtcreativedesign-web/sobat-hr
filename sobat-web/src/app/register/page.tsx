'use client';

import { useState, useEffect, Suspense } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import apiClient from '@/lib/api-client';

function RegisterForm() {
    const router = useRouter();
    const searchParams = useSearchParams();
    const token = searchParams.get('token');

    const [isLoading, setIsLoading] = useState(true);
    const [isValid, setIsValid] = useState(false);
    const [userData, setUserData] = useState<{ name: string; email: string } | null>(null);
    const [error, setError] = useState('');
    const [isSuccess, setIsSuccess] = useState(false);

    const [formData, setFormData] = useState({
        password: '',
        password_confirmation: '',
    });
    const [isSubmitting, setIsSubmitting] = useState(false);

    // Check Token Validity on Mount
    useEffect(() => {
        if (!token) {
            setError('Token invalid atau tidak ditemukan.');
            setIsLoading(false);
            return;
        }

        apiClient.get(`/staff/invite/verify/${token}`)
            .then((res) => {
                setIsValid(res.data.valid);
                setUserData({ name: res.data.name, email: res.data.email });
            })
            .catch((err) => {
                setError(err.response?.data?.message || 'Invitation invalid or expired.');
            })
            .finally(() => {
                setIsLoading(false);
            });
    }, [token]);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (formData.password !== formData.password_confirmation) {
            alert('Password konfirmasi tidak cocok.');
            return;
        }

        setIsSubmitting(true);
        try {
            await apiClient.post('/staff/invite/accept', {
                token,
                password: formData.password,
                password_confirmation: formData.password_confirmation,
            });

            setIsSuccess(true);
            // No auto-login or redirect needed as per request

        } catch (err: any) {
            alert(err.response?.data?.message || 'Gagal mengaktifkan akun.');
            setIsSubmitting(false); // Only re-enable if failed
        }
    };

    if (isSuccess) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#a9eae2] to-[#729892] p-4">
                <div className="max-w-md w-full bg-white/80 backdrop-blur-xl rounded-2xl shadow-2xl overflow-hidden animate-fade-in-up border border-white/50 p-8 text-center">
                    <div className="w-20 h-20 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-6 text-green-600">
                        <svg className="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" /></svg>
                    </div>
                    <h1 className="text-2xl font-bold text-gray-800 mb-4">Pembuatan Akun Berhasil!</h1>
                    <p className="text-gray-600 mb-8">
                        Akun Anda telah aktif. Silahkan login menggunakan aplikasi <span className="font-semibold text-[#462e37]">Sobat Mobile</span>.
                    </p>
                </div>
            </div>
        );
    }

    if (isLoading) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#462e37]"></div>
            </div>
        );
    }

    if (error || !isValid) {
        return (
            <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
                <div className="max-w-md w-full bg-white rounded-2xl shadow-xl p-8 text-center animate-fade-in-up">
                    <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4 text-red-600">
                        <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                    </div>
                    <h2 className="text-xl font-bold text-gray-800 mb-2">Invitation Invalid</h2>
                    <p className="text-gray-500 mb-6">{error || 'Tautan invitasi ini sudah kadaluarsa atau tidak valid.'}</p>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-[#462e37]/5 to-[#a9eae2]/5 p-4">
            <div className="max-w-md w-full bg-white/80 backdrop-blur-xl rounded-2xl shadow-2xl overflow-hidden animate-fade-in-up border border-white/50">
                <div className="p-8">
                    <div className="text-center mb-8">
                        <h1 className="text-2xl font-bold text-[#462e37]">
                            Activate Account
                        </h1>
                        <p className="text-gray-500 mt-2">Halo, <span className="font-semibold text-gray-800">{userData?.name}</span>!</p>
                        <p className="text-sm text-gray-400">{userData?.email}</p>
                    </div>

                    <form onSubmit={handleSubmit} className="space-y-6">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Buat Password Baru</label>
                            <input
                                type="password"
                                required
                                minLength={8}
                                value={formData.password}
                                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                                className="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-[#462e37] focus:ring-2 focus:ring-[#462e37]/20 outline-none transition-all placeholder:text-gray-300"
                                placeholder="Minimal 8 karakter"
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 mb-1">Konfirmasi Password</label>
                            <input
                                type="password"
                                required
                                minLength={8}
                                value={formData.password_confirmation}
                                onChange={(e) => setFormData({ ...formData, password_confirmation: e.target.value })}
                                className="w-full px-4 py-3 rounded-lg border border-gray-200 focus:border-[#462e37] focus:ring-2 focus:ring-[#462e37]/20 outline-none transition-all placeholder:text-gray-300"
                                placeholder="Ulangi password"
                            />
                        </div>

                        <button
                            type="submit"
                            disabled={isSubmitting}
                            className="w-full py-3 px-4 bg-[#462e37] text-[#a9eae2] rounded-lg font-semibold shadow-lg hover:shadow-[#462e37]/30 transform hover:-translate-y-0.5 transition-all disabled:opacity-70 disabled:cursor-not-allowed"
                        >
                            {isSubmitting ? 'Mengaktifkan...' : 'Aktifkan Akun'}
                        </button>
                    </form>
                </div>
            </div>
        </div>
    );
}

export default function RegisterPage() {
    return (
        <Suspense fallback={<div>Loading...</div>}>
            <RegisterForm />
        </Suspense>
    );
}
