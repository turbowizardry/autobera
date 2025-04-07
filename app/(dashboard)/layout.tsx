export default function Layout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <div className="flex-1 space-y-4 p-6 sm:p-8 lg:p-10">
      {children}
    </div>
  );
}
