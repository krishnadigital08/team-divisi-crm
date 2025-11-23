import { useState, useEffect } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { useToast } from '@/hooks/use-toast';
import { UserRole } from '@/contexts/AuthContext';

export interface User {
  id: string;
  display_name: string;
  email: string;
  division_id?: string;
  division_name?: string;
  role?: UserRole;
  created_at: Date;
}

export interface CreateUserData {
  email: string;
  password: string;
  display_name: string;
  role: UserRole;
  division_id?: string;
}

export function useUsers() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(false);
  const { toast } = useToast();

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const { data: profilesData, error: profilesError } = await supabase
        .from('profiles')
        .select(`
          user_id,
          display_name,
          email,
          division_id,
          created_at,
          divisions(name)
        `)
        .order('created_at', { ascending: false });

      if (profilesError) {
        console.error('Error fetching users:', profilesError);
        toast({
          title: "Error",
          description: "Failed to fetch users",
          variant: "destructive",
        });
        return;
      }

      const { data: rolesData, error: rolesError } = await supabase
        .from('user_roles')
        .select('user_id, role');

      if (rolesError) {
        console.error('Error fetching roles:', rolesError);
      }

      const rolesMap = new Map<string, UserRole>();
      (rolesData || []).forEach((role: any) => {
        rolesMap.set(role.user_id, role.role);
      });

      const formattedUsers: User[] = (profilesData || []).map((profile: any) => ({
        id: profile.user_id,
        display_name: profile.display_name,
        email: profile.email,
        division_id: profile.division_id,
        division_name: profile.divisions?.name,
        role: rolesMap.get(profile.user_id),
        created_at: new Date(profile.created_at),
      }));

      setUsers(formattedUsers);
    } catch (error) {
      console.error('Error in fetchUsers:', error);
      toast({
        title: "Error",
        description: "Failed to fetch users",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const createUser = async (userData: CreateUserData) => {
    try {
      // First create the auth user
      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email: userData.email,
        password: userData.password,
        user_metadata: {
          display_name: userData.display_name
        }
      });

      if (authError) {
        toast({
          title: "Error",
          description: authError.message,
          variant: "destructive",
        });
        return;
      }

      if (!authData.user) {
        toast({
          title: "Error",
          description: "Failed to create user",
          variant: "destructive",
        });
        return;
      }

      // Update the profile with division
      if (userData.division_id) {
        const { error: profileError } = await supabase
          .from('profiles')
          .update({ division_id: userData.division_id })
          .eq('user_id', authData.user.id);

        if (profileError) {
          console.error('Error updating profile:', profileError);
        }
      }

      // Assign the role
      const { error: roleError } = await supabase
        .from('user_roles')
        .insert({
          user_id: authData.user.id,
          role: userData.role,
          assigned_by: (await supabase.auth.getUser()).data.user?.id
        });

      if (roleError) {
        console.error('Error assigning role:', roleError);
        toast({
          title: "Warning",
          description: "User created but role assignment failed",
          variant: "destructive",
        });
      } else {
        toast({
          title: "Success",
          description: "User created successfully",
        });
      }

      await fetchUsers();
    } catch (error) {
      console.error('Error creating user:', error);
      toast({
        title: "Error",
        description: "Failed to create user",
        variant: "destructive",
      });
    }
  };

  const updateUser = async (userId: string, userData: Partial<CreateUserData>) => {
    try {
      // Update profile
      const { error: profileError } = await supabase
        .from('profiles')
        .update({
          display_name: userData.display_name,
          division_id: userData.division_id
        })
        .eq('user_id', userId);

      if (profileError) {
        console.error('Error updating profile:', profileError);
        toast({
          title: "Error",
          description: "Failed to update user profile",
          variant: "destructive",
        });
        return;
      }

      // Update role if provided
      if (userData.role) {
        const { error: roleError } = await supabase
          .from('user_roles')
          .update({ role: userData.role })
          .eq('user_id', userId);

        if (roleError) {
          console.error('Error updating role:', roleError);
          toast({
            title: "Error",
            description: "Failed to update user role",
            variant: "destructive",
          });
          return;
        }
      }

      toast({
        title: "Success",
        description: "User updated successfully",
      });

      await fetchUsers();
    } catch (error) {
      console.error('Error updating user:', error);
      toast({
        title: "Error",
        description: "Failed to update user",
        variant: "destructive",
      });
    }
  };

  const deleteUser = async (userId: string) => {
    try {
      // Check if user has assigned customers
      const { data: assignedCustomers, error: customerError } = await supabase
        .from('customers')
        .select('id, name')
        .or(`assigned_to_user_id.eq.${userId},created_by_user_id.eq.${userId},supervisor_user_id.eq.${userId},manager_user_id.eq.${userId}`);

      if (customerError) throw customerError;

      if (assignedCustomers && assignedCustomers.length > 0) {
        toast({
          title: "Cannot delete user",
          description: `User has ${assignedCustomers.length} assigned customers. Reassign them first.`,
          variant: "destructive",
        });
        return;
      }

      const { error } = await supabase.auth.admin.deleteUser(userId);

      if (error) {
        console.error('Error deleting user:', error);
        toast({
          title: "Error",
          description: "Failed to delete user",
          variant: "destructive",
        });
        return;
      }

      toast({
        title: "Success",
        description: "User deleted successfully",
      });

      await fetchUsers();
    } catch (error) {
      console.error('Error deleting user:', error);
      toast({
        title: "Error",
        description: "Failed to delete user",
        variant: "destructive",
      });
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  return {
    users,
    loading,
    createUser,
    updateUser,
    deleteUser,
    refetch: fetchUsers,
  };
}