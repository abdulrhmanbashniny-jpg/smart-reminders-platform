import Image from "next/image";

const companyAr = process.env.NEXT_PUBLIC_COMPANY_NAME_AR ?? "مصنع جدة للدهانات والمعاجين";
const companyEn = process.env.NEXT_PUBLIC_COMPANY_NAME_EN ?? "Jeddah Paint Factory";
const appAr = process.env.NEXT_PUBLIC_APP_NAME_AR ?? "منصة التذكيرات الذكية";
const appEn = process.env.NEXT_PUBLIC_APP_NAME_EN ?? "Smart Reminders Platform";

export default function Header() {
  // Default to light logo; in implementation we can swap based on theme.
  const logoSrc = "/brand/jpf_logo_transparent.png";
  return (
    <header className="header">
      <div className="header-inner">
        <Image src={logoSrc} alt="JPF" width={64} height={32} priority />
        <div className="brand-text">
          <div className="company">{companyAr}</div>
          <div className="company-en">{companyEn}</div>
          <div className="platform">{appAr} | {appEn}</div>
        </div>
      </div>
    </header>
  );
}
