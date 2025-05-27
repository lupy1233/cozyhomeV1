import { Button } from "@/components/ui/button";

export default function FeaturesPage() {
  return (
    <main className="flex-1">
      {/* Hero Section */}
      <section className="py-24 px-4 bg-muted/50">
        <div className="container mx-auto text-center">
          <h1 className="text-4xl font-bold tracking-tight sm:text-6xl mb-6">
            Powerful Features for Your Smart Home
          </h1>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Discover how Cozy Home can transform your living space with our
            comprehensive suite of smart home features.
          </p>
        </div>
      </section>

      {/* Features Grid */}
      <section className="py-24 px-4">
        <div className="container mx-auto">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {/* Smart Automation */}
            <div className="p-6 rounded-lg border">
              <h3 className="text-xl font-semibold mb-4">Smart Automation</h3>
              <p className="text-muted-foreground mb-4">
                Automate your home's systems with intelligent scheduling and
                triggers.
              </p>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li>• Custom automation rules</li>
                <li>• Time-based schedules</li>
                <li>• Location-based triggers</li>
                <li>• Device interactions</li>
              </ul>
            </div>

            {/* Energy Management */}
            <div className="p-6 rounded-lg border">
              <h3 className="text-xl font-semibold mb-4">Energy Management</h3>
              <p className="text-muted-foreground mb-4">
                Monitor and optimize your home's energy consumption.
              </p>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li>• Real-time energy monitoring</li>
                <li>• Usage analytics</li>
                <li>• Energy-saving recommendations</li>
                <li>• Cost tracking</li>
              </ul>
            </div>

            {/* Security */}
            <div className="p-6 rounded-lg border">
              <h3 className="text-xl font-semibold mb-4">Security</h3>
              <p className="text-muted-foreground mb-4">
                Keep your home safe with advanced security features.
              </p>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li>• Smart door locks</li>
                <li>• Security cameras</li>
                <li>• Motion sensors</li>
                <li>• Remote monitoring</li>
              </ul>
            </div>

            {/* Voice Control */}
            <div className="p-6 rounded-lg border">
              <h3 className="text-xl font-semibold mb-4">Voice Control</h3>
              <p className="text-muted-foreground mb-4">
                Control your home with simple voice commands.
              </p>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li>• Amazon Alexa integration</li>
                <li>• Google Assistant support</li>
                <li>• Custom voice commands</li>
                <li>• Multi-room audio</li>
              </ul>
            </div>

            {/* Climate Control */}
            <div className="p-6 rounded-lg border">
              <h3 className="text-xl font-semibold mb-4">Climate Control</h3>
              <p className="text-muted-foreground mb-4">
                Maintain the perfect temperature in every room.
              </p>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li>• Smart thermostats</li>
                <li>• Zone control</li>
                <li>• Humidity monitoring</li>
                <li>• Air quality sensors</li>
              </ul>
            </div>

            {/* Lighting */}
            <div className="p-6 rounded-lg border">
              <h3 className="text-xl font-semibold mb-4">Smart Lighting</h3>
              <p className="text-muted-foreground mb-4">
                Create the perfect ambiance with intelligent lighting.
              </p>
              <ul className="space-y-2 text-sm text-muted-foreground">
                <li>• Color control</li>
                <li>• Scene presets</li>
                <li>• Motion activation</li>
                <li>• Energy-efficient LEDs</li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-24 px-4 bg-muted/50">
        <div className="container mx-auto text-center">
          <h2 className="text-3xl font-bold mb-6">
            Ready to Transform Your Home?
          </h2>
          <p className="text-muted-foreground mb-8 max-w-2xl mx-auto">
            Experience the future of home automation with Cozy Home's
            comprehensive features.
          </p>
          <Button size="lg">Get Started Today</Button>
        </div>
      </section>
    </main>
  );
}
