import "./globals.css";
import Header from "../components/Header";

export const metadata = {
  title: "منصة التذكيرات الذكية",
  description: "Smart Reminders Platform - Jeddah Paint Factory",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ar" dir="rtl">
      <body>
        <Header />
        <main className="container">{children}</main>
      </body>
    </html>
  );
}
