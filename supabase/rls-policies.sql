-- Enable Row Level Security on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.homes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rfqs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rfq_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rfq_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.files ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.offers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view their own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view manufacturer profiles" ON public.users
  FOR SELECT USING (role = 'manufacturer' AND status = 'active');

CREATE POLICY "Admins can view all users" ON public.users
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Homes table policies
CREATE POLICY "Users can view their own homes" ON public.homes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own homes" ON public.homes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own homes" ON public.homes
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own homes" ON public.homes
  FOR DELETE USING (auth.uid() = user_id);

-- Categories table policies (public read access)
CREATE POLICY "Anyone can view active categories" ON public.categories
  FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage categories" ON public.categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- RFQs table policies
CREATE POLICY "Users can view their own RFQs" ON public.rfqs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own RFQs" ON public.rfqs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own RFQs" ON public.rfqs
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own RFQs" ON public.rfqs
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Manufacturers can view active RFQs" ON public.rfqs
  FOR SELECT USING (
    status = 'active' AND 
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'manufacturer'
    )
  );

-- RFQ Categories policies
CREATE POLICY "Users can manage their RFQ categories" ON public.rfq_categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.rfqs 
      WHERE id = rfq_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Manufacturers can view RFQ categories for active RFQs" ON public.rfq_categories
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.rfqs r
      JOIN public.users u ON u.id = auth.uid()
      WHERE r.id = rfq_id AND r.status = 'active' AND u.role = 'manufacturer'
    )
  );

-- RFQ Answers policies
CREATE POLICY "Users can manage their RFQ answers" ON public.rfq_answers
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.rfqs 
      WHERE id = rfq_id AND user_id = auth.uid()
    )
  );

CREATE POLICY "Manufacturers can view RFQ answers for active RFQs" ON public.rfq_answers
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.rfqs r
      JOIN public.users u ON u.id = auth.uid()
      WHERE r.id = rfq_id AND r.status = 'active' AND u.role = 'manufacturer'
    )
  );

-- Files table policies
CREATE POLICY "Users can view their own files" ON public.files
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can upload their own files" ON public.files
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own files" ON public.files
  FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view public files" ON public.files
  FOR SELECT USING (is_public = true);

CREATE POLICY "RFQ participants can view RFQ files" ON public.files
  FOR SELECT USING (
    rfq_id IS NOT NULL AND (
      -- RFQ owner can see files
      EXISTS (
        SELECT 1 FROM public.rfqs 
        WHERE id = rfq_id AND user_id = auth.uid()
      ) OR
      -- Manufacturers who made offers can see files
      EXISTS (
        SELECT 1 FROM public.offers o
        WHERE o.rfq_id = files.rfq_id AND o.manufacturer_id = auth.uid()
      )
    )
  );

-- Offers table policies
CREATE POLICY "Manufacturers can view their own offers" ON public.offers
  FOR SELECT USING (auth.uid() = manufacturer_id);

CREATE POLICY "Manufacturers can create offers" ON public.offers
  FOR INSERT WITH CHECK (
    auth.uid() = manufacturer_id AND
    EXISTS (
      SELECT 1 FROM public.users 
      WHERE id = auth.uid() AND role = 'manufacturer'
    )
  );

CREATE POLICY "Manufacturers can update their own offers" ON public.offers
  FOR UPDATE USING (auth.uid() = manufacturer_id);

CREATE POLICY "RFQ owners can view offers for their RFQs" ON public.offers
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.rfqs 
      WHERE id = rfq_id AND user_id = auth.uid()
    )
  );

-- Messages table policies
CREATE POLICY "Users can view messages they sent or received" ON public.messages
  FOR SELECT USING (
    auth.uid() = sender_id OR auth.uid() = recipient_id
  );

CREATE POLICY "Users can send messages" ON public.messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update messages they sent" ON public.messages
  FOR UPDATE USING (auth.uid() = sender_id);

-- Notifications table policies
CREATE POLICY "Users can view their own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications" ON public.notifications
  FOR INSERT WITH CHECK (true); -- This will be handled by server-side functions

-- Create a function to handle user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, first_name, last_name)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'first_name',
    NEW.raw_user_meta_data->>'last_name'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user creation
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to update user last_login
CREATE OR REPLACE FUNCTION public.update_user_last_login()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.users 
  SET last_login = NOW()
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for login tracking
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW 
  WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
  EXECUTE FUNCTION public.update_user_last_login(); 