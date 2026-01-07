import { createMDX } from 'fumadocs-mdx/next';

const nextConfig = {
  output: 'export',
  basePath: '/synapse',
  trailingSlash: true,
  transpilePackages: ['fumadocs-ui'],
  images: {
    unoptimized: true,
  },
};

const withMDX = createMDX();

export default withMDX(nextConfig);
