import Image from "next/image";
import { Inter } from "next/font/google";
import LandingNavbar from "@/components/LandingNavbar";

const inter = Inter({ subsets: ["latin"] });

export default function Home() {
  return <main>{<LandingNavbar></LandingNavbar>}</main>;
}
