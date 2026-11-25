import { useCallback, useEffect, useRef, useState } from "react";
import { AnimatePresence, motion, useReducedMotion } from "motion/react";
import {
  ArrowRight,
  ArrowUpRight,
  BadgeCheck,
  ChevronLeft,
  ChevronRight,
  GraduationCap,
  HeartHandshake,
  Pause,
  Play,
  ShieldCheck,
  Users,
} from "lucide-react";
import { useApp } from "../context/AppContext";
import { cn } from "@/aoh/lib/utils";

interface Slide {
  image: string;
  eyebrow: string;
  title: string;
  highlight: string;
  description: string;
}

const FALLBACK_SLIDES: Slide[] = [
  {
    image:
      "https://dala-prod-public-storage.s3.eu-west-1.amazonaws.com/attachments/7df501ed-0d87-47d4-9851-c8a5505b89b3/1791902768004_IMG-20250919-WA0127.webp",
    eyebrow: "A. M. Kyne Collegiate Resource Center • Cohort Success",
    title: "Empowering Future",
    highlight: "Tech Leaders & Innovators",
    description:
      "Explore practical programmes from AFRICA OF HOPE, with course duration, study options and registration details in our catalogue.",
  },
  {
    image:
      "https://dala-prod-public-storage.s3.eu-west-1.amazonaws.com/attachments/7df501ed-0d87-47d4-9851-c8a5505b89b3/1791902655944_IMG-20251006-WA0070.webp",
    eyebrow: "Cohort One • Digital Marketing & Financial Literacy",
    title: "Celebrating Our",
    highlight: "Certified Cohort Graduates",
    description:
      "Recognizing ambitious professionals who mastered modern digital growth and financial management skill sets.",
  },
  {
    image:
      "https://dala-prod-public-storage.s3.eu-west-1.amazonaws.com/attachments/7df501ed-0d87-47d4-9851-c8a5505b89b3/1791902768234_IMG-20251117-WA0113.webp",
    eyebrow: "Professional Learning • Certificate Verification",
    title: "Verifiable Credentials That",
    highlight: "Open Real Career Doors",
    description:
      "Use the certificate verification page to check credentials issued through AFRICA OF HOPE.",
  },
  {
    image:
      "https://dala-prod-public-storage.s3.eu-west-1.amazonaws.com/attachments/7df501ed-0d87-47d4-9851-c8a5505b89b3/1791902768357_IMG-20251117-WA0114.webp",
    eyebrow: "Readers Are Leaders • Academic Milestone",
    title: "Excellence in Learning &",
    highlight: "Community Building",
    description:
      "Immersive learning environments equipped with modern digital resources and dedicated faculty mentors.",
  },
  {
    image:
      "https://dala-prod-public-storage.s3.eu-west-1.amazonaws.com/attachments/7df501ed-0d87-47d4-9851-c8a5505b89b3/1791902683385_IMG-20251213-WA0229.jpg",
    eyebrow: "Network • Collaborate • Transform",
    title: "A Dynamic Community of",
    highlight: "Lifelong Learners",
    description:
      "Experience peer collaboration, live project labs, and mentorship that accelerates professional growth.",
  },
];

const AUTOPLAY_MS = 6500;

interface HeroSliderProps {
  onOpenApply: () => void;
  onEnterPortal: () => void;
}

export default function HeroSlider({ onOpenApply, onEnterPortal }: HeroSliderProps) {
  const { state } = useApp();
  const rawSlides =
    state.websiteSettings.heroSlides.length > 0 ? state.websiteSettings.heroSlides : FALLBACK_SLIDES;

  const slides = (rawSlides.length > 0 ? rawSlides : FALLBACK_SLIDES)
    .map((s, i) => ({
      image: (s.image || FALLBACK_SLIDES[i % FALLBACK_SLIDES.length].image).trim(),
      eyebrow: (s.eyebrow || FALLBACK_SLIDES[i % FALLBACK_SLIDES.length].eyebrow || "AFRICA OF HOPE").trim(),
      title: (s.title || FALLBACK_SLIDES[i % FALLBACK_SLIDES.length].title || "Learn practical skills").trim(),
      highlight: (s.highlight || FALLBACK_SLIDES[i % FALLBACK_SLIDES.length].highlight || "").trim(),
      description: (
        s.description ||
        FALLBACK_SLIDES[i % FALLBACK_SLIDES.length].description ||
        "Practical certificate programmes with mentors and verifiable certificates."
      ).trim(),
    }))
    .filter((s) => s.image.length > 0 && (s.title.length > 0 || s.description.length > 0));
  const safeSlides = slides.length > 0 ? slides : FALLBACK_SLIDES;

  const [current, setCurrent] = useState(0);
  const [paused, setPaused] = useState(false);
  const [progress, setProgress] = useState(0);
  const prefersReducedMotion = useReducedMotion();
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const touchX = useRef<number | null>(null);

  const goTo = useCallback(
    (index: number) => {
      const nextIdx = ((index % safeSlides.length) + safeSlides.length) % safeSlides.length;
      setCurrent(nextIdx);
      setProgress(0);
    },
    [safeSlides.length],
  );

  const next = useCallback(() => goTo(current + 1), [current, goTo]);
  const prev = useCallback(() => goTo(current - 1), [current, goTo]);

  useEffect(() => {
    if (paused || prefersReducedMotion || safeSlides.length < 2) return;
    timerRef.current = setInterval(() => {
      setProgress((p) => {
        const step = 100 / (AUTOPLAY_MS / 100);
        if (p + step >= 100) {
          setCurrent((c) => (c + 1) % safeSlides.length);
          return 0;
        }
        return p + step;
      });
    }, 100);
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, [paused, prefersReducedMotion, safeSlides.length, current]);

  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === "ArrowLeft") prev();
      if (e.key === "ArrowRight") next();
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [next, prev]);

  const firstImage = safeSlides[0]?.image;
  const secondImage = safeSlides[1]?.image;
  useEffect(() => {
    try {
      [firstImage, secondImage].forEach((src, i) => {
        if (!src) return;
        const l = document.createElement("link");
        l.rel = "preload";
        l.as = "image";
        l.href = src;
        if (i === 0) l.setAttribute("fetchpriority", "high");
        document.head.appendChild(l);
      });
    } catch {
      /* best-effort */
    }
  }, [firstImage, secondImage]);

  const slide = safeSlides[current % safeSlides.length];
  const copy = state.websiteSettings.publicCopy;
  const badgeText = (copy["hero.badge"] || "").trim();
  const applyLabel = copy["hero.apply"] || "Apply Online";
  const donateLabel = copy["hero.donate"] || "Donate";
  const verifyLabel = copy["hero.verify"] || "Verify Certificate";
  const portalLabel = copy["hero.portal"] || "School Portal Login";

  const idx = current % safeSlides.length;
  const facts = [
    { icon: GraduationCap, value: "31", label: "Certificate programmes" },
    { icon: BadgeCheck, value: "100%", label: "Verifiable certificates" },
    { icon: HeartHandshake, value: "Non-profit", label: "Mission-led school" },
    { icon: Users, value: "2026/27", label: "Intake now open" },
  ];

  return (
    <section
      aria-roledescription="carousel"
      aria-label="Academy highlights"
      onMouseEnter={() => setPaused(true)}
      onMouseLeave={() => setPaused(false)}
      onFocus={() => setPaused(true)}
      onBlur={() => setPaused(false)}
      onTouchStart={(e) => {
        touchX.current = e.touches[0]?.clientX ?? null;
      }}
      onTouchEnd={(e) => {
        if (touchX.current == null) return;
        const dx = e.changedTouches[0].clientX - touchX.current;
        if (Math.abs(dx) > 48) {
          if (dx < 0) next();
          else prev();
        }
        touchX.current = null;
      }}
      className="aoh-hero-v2 relative isolate overflow-hidden bg-emerald-950 text-white"
    >
      {/* Full-bleed photography */}
      <div aria-hidden="true" className="absolute inset-0 -z-10">
        {safeSlides.map((s, i) => {
          const active = i === idx;
          return (
            <div
              key={s.image + i}
              className={cn(
                "absolute inset-0 transition-opacity duration-[1200ms] ease-out",
                active ? "opacity-100" : "opacity-0",
              )}
            >
              <img
                src={s.image}
                alt=""
                draggable={false}
                loading={i === 0 ? "eager" : "lazy"}
                decoding="async"
                className={cn(
                  "h-full w-full object-cover object-center",
                  active && !prefersReducedMotion ? "aoh-hero-kenburns" : "",
                )}
              />
            </div>
          );
        })}
        <div className="absolute inset-0 bg-gradient-to-r from-emerald-950/85 via-emerald-950/35 to-transparent" />
        <div className="absolute inset-0 bg-gradient-to-t from-emerald-950/70 via-transparent to-transparent" />
        <div className="absolute -left-24 bottom-0 h-[26rem] w-[26rem] rounded-full bg-amber-400/10 blur-3xl" />
        <div className="absolute inset-x-0 top-0 h-1.5 bg-gradient-to-r from-amber-400 via-emerald-400 to-amber-400" />
      </div>

      <div className="relative mx-auto flex min-h-[calc(100svh-7rem)] w-full max-w-7xl flex-col justify-between px-4 pb-6 pt-10 sm:px-6 sm:pt-14 lg:px-8">
        <div className="grid items-center gap-10 lg:grid-cols-[1.25fr_0.75fr]">
          {/* Copy */}
          <div className="aoh-hero-copy min-w-0">
            <div className="flex min-w-0 max-w-full flex-wrap items-center gap-2">
              <span className="inline-flex items-center gap-2 rounded-full bg-amber-400 px-3.5 py-1.5 text-[11px] font-extrabold uppercase tracking-[0.16em] text-emerald-950">
                <span className="relative flex h-2 w-2">
                  <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-900 opacity-60" />
                  <span className="relative inline-flex h-2 w-2 rounded-full bg-emerald-900" />
                </span>
                Admissions 2026 / 27
              </span>
              <span className="min-w-0 max-w-full truncate rounded-full border border-white/20 bg-white/10 px-3.5 py-1.5 text-[11px] font-semibold uppercase tracking-[0.12em] text-emerald-50 backdrop-blur">
                {badgeText || slide.eyebrow}
              </span>
            </div>

            <div aria-live="polite" className="mt-6">
              <AnimatePresence mode="wait">
                <motion.div
                  key={current}
                  initial={prefersReducedMotion ? { opacity: 0 } : { opacity: 0, y: 22 }}
                  animate={prefersReducedMotion ? { opacity: 1 } : { opacity: 1, y: 0 }}
                  exit={prefersReducedMotion ? { opacity: 0 } : { opacity: 0, y: -14 }}
                  transition={{ duration: prefersReducedMotion ? 0.2 : 0.5, ease: "easeOut" }}
                >
                  <h1 className="text-balance break-words text-[2.1rem] font-extrabold leading-[1.02] tracking-[-0.03em] text-white min-[480px]:text-5xl sm:text-6xl lg:text-7xl">
                    {slide.title}
                    {slide.highlight ? (
                      <>
                        <br />
                        <span className="bg-gradient-to-r from-amber-300 via-amber-400 to-lime-300 bg-clip-text text-transparent">
                          {slide.highlight}
                        </span>
                      </>
                    ) : null}
                  </h1>
                  <p className="mt-5 max-w-[56ch] text-pretty text-base leading-relaxed text-emerald-50/90 sm:text-lg">
                    {slide.description}
                  </p>
                </motion.div>
              </AnimatePresence>
            </div>

            <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center">
              <button
                type="button"
                onClick={onOpenApply}
                className="group inline-flex h-12 w-full items-center justify-center gap-2 rounded-full bg-amber-400 px-7 text-base font-extrabold text-emerald-950 shadow-[0_18px_40px_-12px_rgba(251,191,36,0.7)] transition hover:bg-amber-300 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-amber-300 focus-visible:ring-offset-2 focus-visible:ring-offset-emerald-950 active:scale-[0.98] sm:w-auto"
              >
                {applyLabel}
                <ArrowRight className="h-5 w-5 transition-transform duration-300 group-hover:translate-x-1" aria-hidden="true" />
              </button>
              <a
                href="#programmes"
                className="inline-flex h-12 w-full items-center justify-center gap-2 rounded-full border border-white/30 bg-white/10 px-7 text-base font-bold text-white backdrop-blur transition hover:bg-white/20 active:scale-[0.98] sm:w-auto"
              >
                Explore programmes
                <ArrowUpRight className="h-5 w-5" aria-hidden="true" />
              </a>
              <a
                href="/donate"
                className="inline-flex h-12 w-full items-center justify-center gap-2 rounded-full px-4 text-base font-bold text-amber-300 underline-offset-4 transition hover:text-amber-200 hover:underline sm:w-auto"
              >
                <HeartHandshake className="h-5 w-5" aria-hidden="true" />
                {donateLabel}
              </a>
            </div>

            <a
              href="/verify"
              className="mt-3 inline-flex min-h-[44px] items-center gap-1.5 text-sm font-semibold text-emerald-100 underline-offset-4 transition hover:text-white hover:underline"
            >
              <ShieldCheck className="h-4 w-4 text-amber-300" aria-hidden="true" />
              {verifyLabel}
            </a>
          </div>

          {/* Slide card */}
          <div className="relative mx-auto w-full max-w-[420px] lg:mx-0 lg:justify-self-end">
            <div className="rounded-[2rem] rounded-tr-[4rem] border border-white/20 bg-white/10 p-3 shadow-2xl shadow-black/30 backdrop-blur-xl">
              <div className="relative aspect-[4/4.4] overflow-hidden rounded-[1.5rem] rounded-tr-[3.2rem] bg-emerald-900">
                {safeSlides.map((s, i) => (
                  <img
                    key={`card-${s.image}-${i}`}
                    src={s.image}
                    alt=""
                    aria-hidden="true"
                    draggable={false}
                    loading={i === 0 ? "eager" : "lazy"}
                    className={cn(
                      "absolute inset-0 h-full w-full object-cover transition-opacity duration-[1000ms]",
                      i === idx ? "opacity-100" : "opacity-0",
                    )}
                  />
                ))}
                <div className="absolute inset-0 bg-gradient-to-t from-emerald-950/55 via-transparent to-transparent" />
                <div className="absolute inset-x-3 bottom-3 flex items-center justify-between gap-2">
                  <p className="min-w-0 truncate text-xs font-bold text-white">
                    <span className="mr-2 tabular-nums text-amber-300">
                      {String(idx + 1).padStart(2, "0")} / {String(safeSlides.length).padStart(2, "0")}
                    </span>
                    {slide.eyebrow}
                  </p>
                  <span className="flex shrink-0 items-center gap-1.5">
                    <button
                      type="button"
                      onClick={prev}
                      aria-label="Previous highlight"
                      className="grid h-9 w-9 place-items-center rounded-full bg-white/15 text-white ring-1 ring-white/30 backdrop-blur transition hover:bg-white/30 active:scale-95"
                    >
                      <ChevronLeft className="h-4 w-4" aria-hidden="true" />
                    </button>
                    <button
                      type="button"
                      onClick={next}
                      aria-label="Next highlight"
                      className="grid h-9 w-9 place-items-center rounded-full bg-amber-400 text-emerald-950 transition hover:bg-amber-300 active:scale-95"
                    >
                      <ChevronRight className="h-4 w-4" aria-hidden="true" />
                    </button>
                    <button
                      type="button"
                      onClick={() => setPaused((p) => !p)}
                      aria-label={paused ? "Resume slideshow" : "Pause slideshow"}
                      aria-pressed={paused}
                      className="grid h-9 w-9 place-items-center rounded-full bg-white/15 text-white ring-1 ring-white/30 backdrop-blur transition hover:bg-white/30 active:scale-95"
                    >
                      {paused ? <Play className="h-4 w-4" aria-hidden="true" /> : <Pause className="h-4 w-4" aria-hidden="true" />}
                    </button>
                  </span>
                </div>
              </div>
              <div className="mt-3 h-1 overflow-hidden rounded-full bg-white/15" aria-hidden="true">
                <div
                  className="h-full rounded-full bg-amber-400 transition-[width] duration-100 ease-linear"
                  style={{ width: `${paused ? 100 : progress}%` }}
                />
              </div>
            </div>

            <div className="absolute -left-4 top-10 hidden items-center gap-2 rounded-2xl bg-amber-400 px-3.5 py-2.5 text-emerald-950 shadow-xl sm:flex lg:-left-10">
              <GraduationCap className="h-5 w-5" aria-hidden="true" />
              <span className="text-xs font-extrabold leading-tight">
                Apply in minutes
                <br />
                <span className="font-semibold">No payment to start</span>
              </span>
            </div>
          </div>
        </div>

        {/* Facts strip */}
        <dl className="mt-10 grid grid-cols-2 gap-px overflow-hidden rounded-2xl border border-white/15 bg-white/15 backdrop-blur lg:grid-cols-4">
          {facts.map(({ icon: Icon, value, label }) => (
            <div key={label} className="flex items-center gap-3 bg-emerald-950/70 px-4 py-4 sm:px-5">
              <span className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-amber-400/15 text-amber-300">
                <Icon className="h-5 w-5" aria-hidden="true" />
              </span>
              <div className="min-w-0">
                <dt className="sr-only">{label}</dt>
                <dd className="text-lg font-extrabold leading-none text-white sm:text-xl">{value}</dd>
                <p className="mt-1 truncate text-[11px] font-semibold uppercase tracking-wider text-emerald-200/80">{label}</p>
              </div>
            </div>
          ))}
        </dl>
      </div>
    </section>
  );
}
