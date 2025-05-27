import { Button } from "@/components/ui/button";
import Image from "next/image";
import Link from "next/link";
import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "About Us | Cozy Home",
  description:
    "Learn about Cozy Home's mission, values, and the team behind your perfect home companion.",
};

const team = [
  {
    name: "Sarah Johnson",
    role: "CEO & Founder",
    image: "/team/sarah.jpg",
    bio: "With over 15 years of experience in smart home technology, Sarah founded Cozy Home to make home automation accessible to everyone.",
  },
  {
    name: "Michael Chen",
    role: "CTO",
    image: "/team/michael.jpg",
    bio: "Michael leads our technical innovation, bringing his expertise in IoT and machine learning to create smarter, more intuitive home solutions.",
  },
  {
    name: "Emily Rodriguez",
    role: "Head of Product",
    image: "/team/emily.jpg",
    bio: "Emily ensures our products meet the highest standards of user experience and functionality, drawing from her background in UX design.",
  },
  {
    name: "David Kim",
    role: "Head of Engineering",
    image: "/team/david.jpg",
    bio: "David oversees our engineering team, focusing on creating reliable and scalable solutions for smart home automation.",
  },
];

export default function AboutPage() {
  return (
    <main className="flex-1">
      {/* Hero Section */}
      <section className="py-24 px-4 bg-muted/50">
        <div className="container mx-auto text-center">
          <h1 className="text-4xl font-bold tracking-tight sm:text-6xl mb-6">
            About Cozy Home
          </h1>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            We're on a mission to make smart home technology accessible,
            intuitive, and beneficial for everyone.
          </p>
        </div>
      </section>

      {/* Story Section */}
      <section className="py-24 px-4">
        <div className="container mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">
            <div>
              <h2 className="text-3xl font-bold mb-6">Our Story</h2>
              <p className="text-muted-foreground mb-4">
                Founded in 2020, Cozy Home began with a simple idea: make smart
                home technology accessible to everyone. We noticed that existing
                solutions were either too complex or too expensive for the
                average homeowner.
              </p>
              <p className="text-muted-foreground mb-4">
                Our team of experts in IoT, AI, and user experience came
                together to create a platform that's both powerful and easy to
                use. We believe that everyone should be able to enjoy the
                benefits of a smart home, regardless of their technical
                expertise.
              </p>
              <p className="text-muted-foreground">
                Today, we're proud to serve thousands of happy customers who
                have transformed their homes into smarter, more efficient living
                spaces.
              </p>
            </div>
            <div className="relative h-[400px] rounded-lg overflow-hidden">
              <Image
                src="/about/office.jpg"
                alt="Cozy Home Office - Our modern workspace where innovation happens"
                fill
                className="object-cover"
                priority
              />
            </div>
          </div>
        </div>
      </section>

      {/* Values Section */}
      <section className="py-24 px-4 bg-muted/50">
        <div className="container mx-auto">
          <h2 className="text-3xl font-bold text-center mb-12">Our Values</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="p-6 rounded-lg bg-background">
              <h3 className="text-xl font-semibold mb-4">Innovation</h3>
              <p className="text-muted-foreground">
                We constantly push the boundaries of what's possible in home
                automation, always looking for ways to make our products better.
              </p>
            </div>
            <div className="p-6 rounded-lg bg-background">
              <h3 className="text-xl font-semibold mb-4">Accessibility</h3>
              <p className="text-muted-foreground">
                We believe smart home technology should be available to
                everyone, regardless of technical expertise or budget.
              </p>
            </div>
            <div className="p-6 rounded-lg bg-background">
              <h3 className="text-xl font-semibold mb-4">Sustainability</h3>
              <p className="text-muted-foreground">
                We're committed to creating solutions that help reduce energy
                consumption and promote sustainable living.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Team Section */}
      <section className="py-24 px-4">
        <div className="container mx-auto">
          <h2 className="text-3xl font-bold text-center mb-12">Our Team</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-8">
            {team.map((member) => (
              <div key={member.name} className="text-center">
                <div className="relative w-48 h-48 mx-auto mb-4 rounded-full overflow-hidden">
                  <Image
                    src={member.image}
                    alt={`${member.name}, ${member.role} at Cozy Home`}
                    width={192}
                    height={192}
                    className="object-cover"
                    onError={(e) => {
                      e.currentTarget.src = "/placeholder-avatar.jpg";
                    }}
                  />
                </div>
                <h3 className="text-xl font-semibold mb-2">{member.name}</h3>
                <p className="text-primary mb-4">{member.role}</p>
                <p className="text-muted-foreground">{member.bio}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24 px-4 bg-muted/50">
        <div className="container mx-auto text-center">
          <h2 className="text-3xl font-bold mb-6">Join Our Journey</h2>
          <p className="text-muted-foreground mb-8 max-w-2xl mx-auto">
            Be part of the future of home automation. We're always looking for
            talented individuals who share our passion for innovation.
          </p>
          <Button asChild size="lg">
            <Link href="/careers">View Open Positions</Link>
          </Button>
        </div>
      </section>
    </main>
  );
}
