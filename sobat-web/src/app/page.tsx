import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="text-center">
        <h1 className="text-6xl font-bold text-gray-900 mb-4">
          SOBAT HR
        </h1>
        <p className="text-xl text-gray-600 mb-8">
          Smart Operations & Business Administrative Tool
        </p>
        <p className="text-gray-500 mb-8">
          Human Resources Information System
        </p>
        <div className="space-x-4">
          <Link
            href="/login"
            className="inline-block px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition"
          >
            Login
          </Link>
          <Link
            href="/dashboard"
            className="inline-block px-6 py-3 bg-white text-blue-600 border border-blue-600 rounded-lg hover:bg-blue-50 transition"
          >
            Dashboard
          </Link>
        </div>
        
        <div className="mt-12 text-sm text-gray-500">
          <p>Built with Next.js 15 + TypeScript + Tailwind CSS</p>
        </div>
      </div>
    </div>
  );
}
