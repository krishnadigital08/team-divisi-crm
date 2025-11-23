import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from '@/hooks/use-toast';
import type { SystemSetting, CompanySetting, UserPreference, NotificationSetting } from '@/types/settings';

export const useSystemSettings = () => {
  const { user } = useAuth();
  const [settings, setSettings] = useState<SystemSetting[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSettings = async () => {
    if (!user) {
      setLoading(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from('system_settings')
        .select('*')
        .order('category', { ascending: true });

      if (error) throw error;
      setSettings(data || []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch settings');
    } finally {
      setLoading(false);
    }
  };

  const updateSetting = async (key: string, value: any) => {
    try {
      const { error } = await supabase
        .from('system_settings')
        .update({ value })
        .eq('key', key);

      if (error) throw error;

      setSettings(prev => prev.map(setting =>
        setting.key === key ? { ...setting, value } : setting
      ));

      toast({
        title: "Success",
        description: "Setting updated successfully",
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update setting';
      setError(message);
      toast({
        title: "Error",
        description: message,
        variant: "destructive",
      });
    }
  };

  useEffect(() => {
    fetchSettings();
  }, [user]);

  return { settings, loading, error, updateSetting, refetch: fetchSettings };
};

export const useCompanySettings = () => {
  const { user } = useAuth();
  const [settings, setSettings] = useState<CompanySetting | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSettings = async () => {
    if (!user) {
      setLoading(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from('company_settings')
        .select('*')
        .limit(1)
        .maybeSingle();

      if (error) throw error;
      setSettings(data || null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch company settings');
    } finally {
      setLoading(false);
    }
  };

  const updateSettings = async (data: Partial<CompanySetting>) => {
    try {
      let result;

      if (settings) {
        result = await supabase
          .from('company_settings')
          .update(data)
          .eq('id', settings.id)
          .select()
          .maybeSingle();
      } else {
        const insertData = {
          company_name: 'Your Company Name',
          ...data
        };
        result = await supabase
          .from('company_settings')
          .insert(insertData)
          .select()
          .maybeSingle();
      }

      if (result.error) throw result.error;

      setSettings(result.data);
      toast({
        title: "Success",
        description: "Company settings updated successfully",
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update company settings';
      setError(message);
      toast({
        title: "Error",
        description: message,
        variant: "destructive",
      });
    }
  };

  useEffect(() => {
    fetchSettings();
  }, [user]);

  return { settings, loading, error, updateSettings, refetch: fetchSettings };
};

export const useUserPreferences = () => {
  const { user } = useAuth();
  const [preferences, setPreferences] = useState<UserPreference | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchPreferences = async () => {
    if (!user) return;
    
    try {
      const { data, error } = await supabase
        .from('user_preferences')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle();

      if (error) throw error;
      setPreferences(data ? data as UserPreference : null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch preferences');
    } finally {
      setLoading(false);
    }
  };

  const updatePreferences = async (data: Partial<UserPreference>) => {
    if (!user) return;
    
    try {
      let result;
      
      if (preferences) {
        result = await supabase
          .from('user_preferences')
          .update(data)
          .eq('user_id', user.id)
          .select()
          .single();
      } else {
        result = await supabase
          .from('user_preferences')
          .insert({ ...data, user_id: user.id })
          .select()
          .single();
      }

      if (result.error) throw result.error;
      
      setPreferences(result.data as UserPreference);
      toast({
        title: "Success",
        description: "Preferences updated successfully",
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update preferences';
      setError(message);
      toast({
        title: "Error",
        description: message,
        variant: "destructive",
      });
    }
  };

  useEffect(() => {
    fetchPreferences();
  }, [user]);

  return { preferences, loading, error, updatePreferences, refetch: fetchPreferences };
};

export const useNotificationSettings = () => {
  const { user } = useAuth();
  const [settings, setSettings] = useState<NotificationSetting | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchSettings = async () => {
    if (!user) return;
    
    try {
      const { data, error } = await supabase
        .from('notification_settings')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle();

      if (error) throw error;
      setSettings(data || null);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch notification settings');
    } finally {
      setLoading(false);
    }
  };

  const updateSettings = async (data: Partial<NotificationSetting>) => {
    if (!user) return;
    
    try {
      let result;
      
      if (settings) {
        result = await supabase
          .from('notification_settings')
          .update(data)
          .eq('user_id', user.id)
          .select()
          .single();
      } else {
        result = await supabase
          .from('notification_settings')
          .insert({ ...data, user_id: user.id })
          .select()
          .single();
      }

      if (result.error) throw result.error;
      
      setSettings(result.data as NotificationSetting);
      toast({
        title: "Success",
        description: "Notification settings updated successfully",
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update notification settings';
      setError(message);
      toast({
        title: "Error",
        description: message,
        variant: "destructive",
      });
    }
  };

  useEffect(() => {
    fetchSettings();
  }, [user]);

  return { settings, loading, error, updateSettings, refetch: fetchSettings };
};