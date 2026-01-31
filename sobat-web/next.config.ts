import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: 'http',
        hostname: 'localhost',
      },
      {
        protocol: 'http',
        hostname: '127.0.0.1',
      },
      {
        protocol: 'http',
        hostname: '202.10.47.156',
      },
      {
        protocol: 'http',
        hostname: '172.23.47.134',
      },
      {
        protocol: 'http',
        hostname: '192.168.0.127',
      },
    ],
  },
};

export default nextConfig;
