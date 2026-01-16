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
    const [organizations, setOrganizations] = useState<any[]>([]);
    const [invitationData, setInvitationData] = useState<any>(null);

    const [formData, setFormData] = useState({
        password: '',
        password_confirmation: '',
        job_level: 'staff',
        track: 'office',
        organization_id: '',
        role: 'staff'
    });
    const [isSubmitting, setIsSubmitting] = useState(false);

    // Check Token Validity on Mount
    useEffect(() => {
        if (!token) {
            setError('Token invalid atau tidak ditemukan.');
            setIsLoading(false);
            return;
        }

        // Fetch Organizations
        apiClient.get('/organizations').then(res => {
            setOrganizations(res.data.data || res.data || []);
        }).catch(err => console.error(err));

        apiClient.get(`/staff/invite/verify/${token}`)
            .then((res) => {
                setIsValid(res.data.valid);
                setUserData({ name: res.data.name, email: res.data.email });
                setInvitationData(res.data);

                // Pre-fill if available
                if (res.data.organization_id) {
                    setFormData(prev => ({ ...prev, organization_id: res.data.organization_id }));
                }
                // Determine track based on org? Or just default.
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
                job_level: formData.job_level,
                track: formData.track,
                organization_id: formData.organization_id,
                role: formData.role
            });

            setIsSuccess(true);
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
                        Akun Anda telah aktif, Jabatan dan Divisi berhasil disimpan. Silahkan login menggunakan aplikasi <span className="font-semibold text-[#462e37]">Sobat Mobile</span>.
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
                        <p className="text-xs text-gray-500 mt-4 bg-yellow-50 p-2 rounded border border-yellow-100">Silakan lengkapi data jabatan dan divisi Anda di bawah ini.</p>
                    </div>

                    <form onSubmit={handleSubmit} className="space-y-4">
                        {/* Job Details Section */}
                        <div className="space-y-3 pt-2">
                            <div>
                                <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Track (Jalur Karir)</label>
                                <select
                                    className="w-full px-4 py-2 border rounded-lg text-sm bg-white"
                                    value={formData.track}
                                    onChange={e => setFormData({ ...formData, track: e.target.value, job_level: e.target.value === 'office' ? 'staff' : 'crew' })}
                                >
                                    <option value="office">Office (Kantor)</option>
                                    <option value="operational">Operational (Lapangan/Outlet)</option>
                                </select>
                            </div>

                            <div>
                                <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Job Level (Jabatan)</label>
                                <select
                                    className="w-full px-4 py-2 border rounded-lg text-sm bg-white"
                                    value={formData.job_level}
                                    onChange={e => setFormData({ ...formData, job_level: e.target.value })}
                                >
                                    {formData.track === 'office' ? (
                                        <>
                                            <option value="staff">Staff</option>
                                            <option value="team_leader">Team Leader</option>
                                            <option value="spv">Supervisor</option>
                                            <option value="deputy_manager">Deputy Manager</option>
                                            <option value="manager">Manager</option>
                                            <option value="director">Director</option>
                                        </>
                                    ) : (
                                        <>
                                            <option value="crew">Crew</option>
                                            <option value="crew_leader">Crew Leader</option>
                                            <option value="spv">Supervisor</option>
                                            <option value="manager_ops">Operational Manager</option>
                                        </>
                                    )}
                                </select>
                            </div>

                            <div>
                                <label className="block text-xs font-semibold text-gray-500 uppercase tracking-wider mb-1">Divisi / Penempatan</label>
                                <select
                                    className="w-full px-4 py-2 border rounded-lg text-sm bg-white"
                                    value={formData.organization_id}
                                    onChange={e => setFormData({ ...formData, organization_id: e.target.value })}
                                    required
                                >
                                    <option value="">Pilih Divisi...</option>
                                    {organizations
                                        .filter(org => !['Board Of Directors', 'Holdings'].includes(org.type))
                                        .map(org => (
                                            <option key={org.id} value={org.id}>{org.name}</option>
                                        ))}
                                </select>
                            </div>
                        </div>

                        <hr className="border-gray-100 my-4" />

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
