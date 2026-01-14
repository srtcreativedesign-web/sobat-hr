import Link from "next/link";

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-[#a9eae2] to-[#729892] text-[#462e37] flex flex-col items-center justify-center p-8 relative overflow-hidden">

      {/* Background Decorative Blobs */}
      <div className="absolute top-0 left-0 w-96 h-96 bg-[#462e37]/10 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2 animate-pulse"></div>
      <div className="absolute bottom-0 right-0 w-[500px] h-[500px] bg-[#462e37]/10 rounded-full blur-3xl translate-x-1/3 translate-y-1/3"></div>

      <main className="relative z-10 text-center max-w-4xl mx-auto space-y-8 animate-fade-in-up">
        {/* Logo / Badge */}
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[#462e37]/10 backdrop-blur-md border border-[#462e37]/10 shadow-lg">
          <span className="w-2 h-2 rounded-full bg-[#462e37] animate-pulse"></span>
          <span className="text-[#462e37] font-semibold tracking-wider text-sm uppercase">
            Human Resource Information System
          </span>
        </div>

        {/* Hero Title */}
        <h1 className="text-5xl md:text-7xl font-bold tracking-tight text-[#462e37] mb-6 drop-shadow-lg">
          SOBAT <span className="text-white">HR</span>
        </h1>

        {/* Subtitle */}
        <p className="text-xl md:text-2xl text-[#462e37]/80 max-w-2xl mx-auto leading-relaxed">
          Platform manajemen SDM modern untuk efisiensi dan produktivitas karyawan perusahaan Anda.
        </p>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-6 mt-12">
          <Link
            href="/login"
            className="group relative px-8 py-4 bg-[#462e37] text-[#a9eae2] font-bold text-lg rounded-xl shadow-[0_0_20px_rgba(70,46,55,0.3)] hover:shadow-[0_0_30px_rgba(70,46,55,0.5)] hover:scale-105 transition-all duration-300"
          >
            Get Started
            <span className="absolute inset-0 rounded-xl bg-white/20 opacity-0 group-hover:opacity-100 transition-opacity"></span>
          </Link>

          <Link
            href="/about"
            className="px-8 py-4 bg-white/40 backdrop-blur-sm border border-white/40 text-[#462e37] font-medium text-lg rounded-xl hover:bg-white/60 hover:border-[#462e37]/20 transition-all duration-300"
          >
            Learn More
          </Link>
        </div>
      </main>

      {/* Footer */}
      <footer className="absolute bottom-8 text-center text-sm text-gray-400">
        &copy; 2026 SRT Corp All rights reserved.
      </footer>
    </div>
  );
}
