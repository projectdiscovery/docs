module.exports = {
  async redirects() {
    return [
      {
        source: '/tools/:path*',
        destination: '/opensource/:path*',
        permanent: true,
      },
    ];
  },
};
