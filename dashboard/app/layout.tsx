import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "SafeCar Fleet | Central de Operações",
  description: "Painel Web para gestão de veículos, viagens e alertas do SafeCar Fleet.",
  icons: { icon: "/icon.svg", shortcut: "/icon.svg" },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="pt-BR">
      <body>{children}</body>
    </html>
  );
}
