/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './app/views/**/*.{erb,html}',
    './app/components/**/*.{erb,rb,html}',
    './app/helpers/**/*.rb',
    './lib/**/*.rb'
  ],
  theme: {
    extend: {
      animation: {
        'slide-in': 'slideIn 0.3s ease-out',
        'fade-out': 'fadeOut 0.3s ease-out',
      },
      keyframes: {
        slideIn: {
          '0%': { transform: 'translateX(100%)', opacity: '0' },
          '100%': { transform: 'translateX(0)', opacity: '1' },
        },
        fadeOut: {
          '0%': { opacity: '1' },
          '100%': { opacity: '0' },
        },
      },
      backgroundImage: {
        'gradient-blue': 'linear-gradient(135deg, #e0f2fe 0%, #bae6fd 100%)',
        'gradient-green': 'linear-gradient(135deg, #d1fae5 0%, #a7f3d0 100%)',
        'gradient-yellow': 'linear-gradient(135deg, #fef3c7 0%, #fde68a 100%)',
        'gradient-red': 'linear-gradient(135deg, #fee2e2 0%, #fecaca 100%)',
      },
      colors: {
        'blue-opacity': 'rgba(59, 130, 246, 0.1)',
        'green-opacity': 'rgba(34, 197, 94, 0.1)',
        'yellow-opacity': 'rgba(234, 179, 8, 0.1)',
        'red-opacity': 'rgba(239, 68, 68, 0.1)',
      },
    },
  },
  plugins: [],
}
