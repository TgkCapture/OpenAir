/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  darkMode: "class",
  theme: {
    extend: {
      colors: {
        primary: "#E63946",
        surface: "#1A1A1A",
        background: "#0F0F0F",
      },
    },
  },
  plugins: [],
};