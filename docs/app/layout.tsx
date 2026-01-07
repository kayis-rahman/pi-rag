import type { Metadata } from "next";
import { Inter } from "next/font/google";
import './globals.css';
import { ThemeProvider } from "next-themes";
import { RootProvider } from "fumadocs-ui/provider";

const inter = Inter({ subsets: ['latin'] });

export const metadata: Metadata = {
  title: 'SYNAPSE Documentation',
  description: 'Your Data Meets Intelligence',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <body className={inter.className}>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          <RootProvider>
            {children}
          </RootProvider>
        </ThemeProvider>
      </body>
    </html>
  );
}
