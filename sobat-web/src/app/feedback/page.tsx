'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import DashboardLayout from '@/components/DashboardLayout';
import apiClient from '@/lib/api-client';

interface Feedback {
    id: number;
    subject: string;
    category: string;
    description: string;
    screenshot_path: string | null;
    status: 'pending' | 'in_progress' | 'resolved' | 'closed';
    admin_response: string | null;
    created_at: string;
    user: {
        id: number;
        name: string;
        email: string;
    };
}

export default function FeedbackPage() {
    const router = useRouter();
    const { user, isAuthenticated } = useAuthStore();
    const [feedbacks, setFeedbacks] = useState<Feedback[]>([]);
    const [loading, setLoading] = useState(true);
    const [selectedFeedback, setSelectedFeedback] = useState<Feedback | null>(null);
    const [filterStatus, setFilterStatus] = useState<string>('all');
    const [filterCategory, setFilterCategory] = useState<string>('all');
    const [searchQuery, setSearchQuery] = useState('');

    useEffect(() => {
        if (!isAuthenticated) {
            router.push('/login');
            return;
        }
        fetchFeedbacks();
    }, [isAuthenticated, router, filterStatus, filterCategory, searchQuery]);

    const fetchFeedbacks = async () => {
        try {
            setLoading(true);
            const params = new URLSearchParams();
            if (filterStatus !== 'all') params.append('status', filterStatus);
            if (filterCategory !== 'all') params.append('category', filterCategory);
            if (searchQuery) params.append('search', searchQuery);

            const response = await apiClient.get(`/admin/feedbacks?${params.toString()}`);
            if (response.data.success) {
                setFeedbacks(response.data.data.data || response.data.data);
            }
        } catch (error) {
            console.error('Failed to fetch feedbacks:', error);
        } finally {
            setLoading(false);
        }
    };

    const updateStatus = async (feedbackId: number, newStatus: string) => {
        try {
            const response = await apiClient.put(`/admin/feedbacks/${feedbackId}`, {
                status: newStatus,
            });

            if (response.data.success) {
                fetchFeedbacks();
                if (selectedFeedback?.id === feedbackId) {
                    setSelectedFeedback({ ...selectedFeedback, status: newStatus as any });
                }
            }
        } catch (error) {
            console.error('Failed to update status:', error);
        }
    };

    const getCategoryBadge = (category: string) => {
        const badges: Record<string, string> = {
            bug: 'bg-red-100 text-red-800',
            feature_request: 'bg-blue-100 text-blue-800',
            complaint: 'bg-yellow-100 text-yellow-800',
            question: 'bg-purple-100 text-purple-800',
            other: 'bg-gray-100 text-gray-800',
        };
        return badges[category] || badges.other;
    };

    const getStatusBadge = (status: string) => {
        const badges: Record<string, string> = {
            pending: 'bg-yellow-100 text-yellow-800',
            in_progress: 'bg-blue-100 text-blue-800',
            resolved: 'bg-green-100 text-green-800',
            closed: 'bg-gray-100 text-gray-800',
        };
        return badges[status] || badges.pending;
    };

    const formatCategory = (category: string) => {
        return category.replace(/_/g, ' ').replace(/\b\w/g, (l) => l.toUpperCase());
    };

    return (
        <DashboardLayout>
            <div className="p-8">
                {/* Header */}
                <div className="mb-8">
                    <h1 className="text-2xl font-bold text-gray-900">User Feedback</h1>
                    <p className="mt-1 text-sm text-gray-600">
                        Manage and respond to user feedback and suggestions
                    </p>
                </div>

                {/* Filters */}
                <div className="mb-6 flex flex-wrap gap-4">
                    <input
                        type="text"
                        placeholder="Search by subject or user..."
                        className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-cyan-500 focus:border-transparent"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />

                    <select
                        className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-cyan-500"
                        value={filterStatus}
                        onChange={(e) => setFilterStatus(e.target.value)}
                    >
                        <option value="all">All Status</option>
                        <option value="pending">Pending</option>
                        <option value="in_progress">In Progress</option>
                        <option value="resolved">Resolved</option>
                        <option value="closed">Closed</option>
                    </select>

                    <select
                        className="px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-cyan-500"
                        value={filterCategory}
                        onChange={(e) => setFilterCategory(e.target.value)}
                    >
                        <option value="all">All Categories</option>
                        <option value="bug">Bug Report</option>
                        <option value="feature_request">Feature Request</option>
                        <option value="complaint">Complaint</option>
                        <option value="question">Question</option>
                        <option value="other">Other</option>
                    </select>
                </div>

                {/* Table */}
                {loading ? (
                    <div className="flex justify-center items-center h-64">
                        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-cyan-500"></div>
                    </div>
                ) : (
                    <div className="bg-white rounded-lg shadow overflow-hidden">
                        <table className="min-w-full divide-y divide-gray-200">
                            <thead className="bg-gray-50">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Date
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        User
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Subject
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Category
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Status
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Actions
                                    </th>
                                </tr>
                            </thead>
                            <tbody className="bg-white divide-y divide-gray-200">
                                {feedbacks.length === 0 ? (
                                    <tr>
                                        <td colSpan={6} className="px-6 py-8 text-center text-gray-500">
                                            No feedback found
                                        </td>
                                    </tr>
                                ) : (
                                    feedbacks.map((feedback) => (
                                        <tr
                                            key={feedback.id}
                                            className="hover:bg-gray-50 cursor-pointer transition-colors"
                                            onClick={() => setSelectedFeedback(feedback)}
                                        >
                                            <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                                                {new Date(feedback.created_at).toLocaleDateString()}
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <div className="text-sm font-medium text-gray-900">
                                                    {feedback.user.name}
                                                </div>
                                                <div className="text-sm text-gray-500">{feedback.user.email}</div>
                                            </td>
                                            <td className="px-6 py-4 text-sm text-gray-900">
                                                {feedback.subject}
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <span
                                                    className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getCategoryBadge(
                                                        feedback.category
                                                    )}`}
                                                >
                                                    {formatCategory(feedback.category)}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap">
                                                <span
                                                    className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getStatusBadge(
                                                        feedback.status
                                                    )}`}
                                                >
                                                    {formatCategory(feedback.status)}
                                                </span>
                                            </td>
                                            <td className="px-6 py-4 whitespace-nowrap text-sm font-medium">
                                                <button
                                                    onClick={(e) => {
                                                        e.stopPropagation();
                                                        setSelectedFeedback(feedback);
                                                    }}
                                                    className="text-cyan-600 hover:text-cyan-900"
                                                >
                                                    View
                                                </button>
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                )}

                {/* Detail Modal */}
                {selectedFeedback && (
                    <div
                        className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50"
                        onClick={() => setSelectedFeedback(null)}
                    >
                        <div
                            className="bg-white rounded-lg max-w-2xl w-full max-h-[90vh] overflow-y-auto"
                            onClick={(e) => e.stopPropagation()}
                        >
                            <div className="p-6">
                                <div className="flex justify-between items-start mb-4">
                                    <h2 className="text-2xl font-bold text-gray-900">
                                        {selectedFeedback.subject}
                                    </h2>
                                    <button
                                        onClick={() => setSelectedFeedback(null)}
                                        className="text-gray-400 hover:text-gray-600"
                                    >
                                        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                        </svg>
                                    </button>
                                </div>

                                <div className="space-y-4">
                                    <div>
                                        <label className="text-sm font-medium text-gray-700">User</label>
                                        <p className="mt-1 text-sm text-gray-900">
                                            {selectedFeedback.user.name} ({selectedFeedback.user.email})
                                        </p>
                                    </div>

                                    <div>
                                        <label className="text-sm font-medium text-gray-700">Category</label>
                                        <p className="mt-1">
                                            <span
                                                className={`px-2 py-1 inline-flex text-xs leading-5 font-semibold rounded-full ${getCategoryBadge(
                                                    selectedFeedback.category
                                                )}`}
                                            >
                                                {formatCategory(selectedFeedback.category)}
                                            </span>
                                        </p>
                                    </div>

                                    <div>
                                        <label className="text-sm font-medium text-gray-700">Status</label>
                                        <select
                                            className="mt-1 block w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-cyan-500 focus:border-cyan-500"
                                            value={selectedFeedback.status}
                                            onChange={(e) => updateStatus(selectedFeedback.id, e.target.value)}
                                        >
                                            <option value="pending">Pending</option>
                                            <option value="in_progress">In Progress</option>
                                            <option value="resolved">Resolved</option>
                                            <option value="closed">Closed</option>
                                        </select>
                                    </div>

                                    <div>
                                        <label className="text-sm font-medium text-gray-700">Description</label>
                                        <p className="mt-1 text-sm text-gray-900 whitespace-pre-wrap">
                                            {selectedFeedback.description}
                                        </p>
                                    </div>

                                    {selectedFeedback.screenshot_path && (
                                        <div>
                                            <label className="text-sm font-medium text-gray-700">Screenshot</label>
                                            <img
                                                src={`${process.env.NEXT_PUBLIC_API_URL}/storage/${selectedFeedback.screenshot_path}`}
                                                alt="Feedback screenshot"
                                                className="mt-2 rounded-lg border border-gray-200 max-w-full"
                                            />
                                        </div>
                                    )}

                                    <div>
                                        <label className="text-sm font-medium text-gray-700">Submitted</label>
                                        <p className="mt-1 text-sm text-gray-900">
                                            {new Date(selectedFeedback.created_at).toLocaleString()}
                                        </p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                )}
            </div>
        </DashboardLayout>
    );
}
