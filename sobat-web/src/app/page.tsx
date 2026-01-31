import Link from "next/link";
import DarkVeil from "@/components/DarkVeil";
import RotatingText from "@/components/RotatingText";

export default function Home() {
  return (
    <div className="min-h-screen relative overflow-hidden flex flex-col items-center justify-center p-8">
      {/* Dynamic Background */}
      {/* Dynamic Background */}
      <div className="absolute inset-0 z-0 bg-black">
        {/* Fallback Image */}
        <div className="absolute inset-0 z-0 opacity-40">
          <img
            src="/assets/welcome-bg.png"
            alt="Background"
            className="w-full h-full object-cover"
          />
        </div>

        {/* Dynamic Background Shader */}
        <div className="absolute inset-0 z-10 opacity-70 mix-blend-screen">
          <DarkVeil
            hueShift={110}
            noiseIntensity={0.2}
            scanlineIntensity={0.3}
            speed={0.2}
            scanlineFrequency={200}
            warpAmount={0.5}
          />
        </div>

        {/* Gradient Overlay */}
        <div className="absolute inset-0 z-20 bg-gradient-to-t from-[#462e37]/40 via-transparent to-transparent"></div>
      </div>

      <main className="relative z-10 text-center max-w-4xl mx-auto space-y-8 animate-fade-in-up">
        {/* Logo / Badge */}
        <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-[#a9eae2]/90 backdrop-blur-md border border-[#729892]/20 shadow-lg">
          <span className="w-2 h-2 rounded-full bg-[#462e37] animate-pulse"></span>
          <span className="text-[#462e37] font-semibold tracking-wider text-sm uppercase">
            Human Resource Information System
          </span>
        </div>

        {/* Hero Title */}
        <h1 className="text-5xl md:text-7xl font-bold tracking-tight text-white mb-2 drop-shadow-lg">
          SOBAT <span className="text-[#a9eae2]">HR</span>
        </h1>

        {/* Rotating Text Animation */}
        <div className="flex justify-center items-center mb-6">
          <span className="text-2xl md:text-3xl text-white mr-3 font-medium">Is</span>
          <RotatingText
            texts={['Modern', 'Efficient', 'Reliable', 'Simple']}
            mainClassName="px-3 sm:px-3 md:px-4 bg-[#a9eae2] text-[#462e37] overflow-hidden py-1 sm:py-2 md:py-2 justify-center rounded-xl text-lg md:text-2xl font-bold"
            staggerFrom="last"
            initial={{ y: "100%" }}
            animate={{ y: 0 }}
            exit={{ y: "-120%" }}
            staggerDuration={0.025}
            splitLevelClassName="overflow-hidden pb-0.5 sm:pb-1 md:pb-1"
            transition={{ type: "spring", damping: 30, stiffness: 400 }}
            rotationInterval={2000}
          />
        </div>

        {/* Subtitle */}
        <p className="text-xl md:text-2xl text-white/90 max-w-2xl mx-auto leading-relaxed drop-shadow-md">
          Platform manajemen SDM modern untuk efisiensi dan produktivitas karyawan perusahaan Anda.
        </p>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-6 mt-12">
          <Link
            href="/login"
            className="group relative px-8 py-4 bg-[#a9eae2] text-[#462e37] font-bold text-lg rounded-xl shadow-[0_0_20px_rgba(169,234,226,0.3)] hover:shadow-[0_0_30px_rgba(169,234,226,0.5)] hover:scale-105 transition-all duration-300"
          >
            Get Started
            <span className="absolute inset-0 rounded-xl bg-white/20 opacity-0 group-hover:opacity-100 transition-opacity"></span>
          </Link>

          <Link
            href="/about"
            className="px-8 py-4 bg-white/10 backdrop-blur-sm border border-white/40 text-white font-medium text-lg rounded-xl hover:bg-white/20 hover:border-white/60 transition-all duration-300"
          >
            Learn More
          </Link>
        </div>
      </main>

      {/* Footer */}
      <footer className="absolute bottom-8 text-center text-sm text-white/60">
        &copy; 2026 SRT Corp All rights reserved.
      </footer>
    </div>
  );
}
