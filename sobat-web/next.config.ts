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
        hostname: '192.168.1.22',
      },
      {
        protocol: 'http',
        hostname: '192.168.1.19',
      },
      {
        protocol: 'http',
        hostname: '192.168.0.105',
      },
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
      },
      {
        protocol: 'https',
        hostname: 'api.sobat-hr.com',
      },
    ],
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  typescript: {
    ignoreBuildErrors: true,
  },
  webpack: (config, { dev }) => {
    if (dev) {
      config.module.rules.push({
        test: /\.mjs$/,
        enforce: 'pre',
        use: [
          {
            loader: 'string-replace-loader',
            options: {
              search: /\/\/# sourceMappingURL=(.*)\.map/g,
              replace: '',
            },
          },
        ],
      });
    }
    return config;
  },
};

export default nextConfig;
