import "./globals.css";
import TopNavClient from "@/components/TopNavClient";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <TopNavClient />
        <main className="max-w-4xl mx-auto p-4">{children}</main>
      </body>
    </html>
  );
}
