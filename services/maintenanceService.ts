import { createClient, RealtimeChannel } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://dxnhamtphxfehdjjuepr.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_mpNENrjciuqRq4Jb4amg9A_Xe5u0rnv';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export type ComplaintPriority = 'P1 - Critical' | 'P2 - High' | 'P3 - Medium' | 'P4 - Low';
export type ComplaintStatus = 'Pending' | 'In Progress' | 'Completed';

export interface MaintenanceComplaint {
  id: string;
  site_id: 'OWP' | 'TPT' | 'WIM' | string;
  s_no?: number;
  equipment: string;
  category: string;
  problem: string;
  priority: ComplaintPriority;
  reported_by?: string;
  responsible_person?: string;
  action_taken?: string;
  vendor?: string;
  complaint_date?: string;
  due_date?: string;
  completed_date?: string | null;
  status: ComplaintStatus;
  remarks?: string;
  created_at?: string;
  updated_at?: string;
}

/**
 * Fetch maintenance complaints with optional filters.
 */
export async function fetchComplaints(
  siteId?: string,
  priority?: string,
  status?: string
): Promise<MaintenanceComplaint[]> {
  let query = supabase.from('maintenance_complaints').select('*');

  if (siteId && siteId !== 'ALL') {
    query = query.eq('site_id', siteId);
  }
  if (priority && priority !== 'ALL') {
    query = query.eq('priority', priority);
  }
  if (status && status !== 'ALL') {
    query = query.eq('status', status);
  }

  const { data, error } = await query
    .order('site_id', { ascending: true })
    .order('s_no', { ascending: true });

  if (error) {
    throw new Error(`Failed to fetch complaints: ${error.message}`);
  }

  return (data as MaintenanceComplaint[]) || [];
}

/**
 * Updates complaint status. If status is 'Completed', automatically sets completed_date = CURRENT_DATE.
 */
export async function updateComplaintStatus(
  id: string,
  status: ComplaintStatus
): Promise<MaintenanceComplaint> {
  const updatePayload: Partial<MaintenanceComplaint> = {
    status,
    updated_at: new Date().toISOString(),
    completed_date: status === 'Completed' ? new Date().toISOString().split('T')[0] : null,
  };

  const { data, error } = await supabase
    .from('maintenance_complaints')
    .update(updatePayload)
    .eq('id', id)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to update status for ${id}: ${error.message}`);
  }

  return data as MaintenanceComplaint;
}

/**
 * Inserts a new maintenance complaint record.
 */
export async function insertComplaint(
  complaintData: Partial<MaintenanceComplaint>
): Promise<MaintenanceComplaint> {
  const payload = {
    ...complaintData,
    id: complaintData.id || `MNT-${complaintData.site_id || 'GEN'}-${Date.now().toString().slice(-6)}`,
    status: complaintData.status || 'Pending',
    complaint_date: complaintData.complaint_date || new Date().toISOString().split('T')[0],
    due_date: complaintData.due_date || new Date().toISOString().split('T')[0],
  };

  const { data, error } = await supabase
    .from('maintenance_complaints')
    .insert(payload)
    .select()
    .single();

  if (error) {
    throw new Error(`Failed to insert complaint: ${error.message}`);
  }

  return data as MaintenanceComplaint;
}

/**
 * Deletes a complaint by ID.
 */
export async function deleteComplaint(id: string): Promise<void> {
  const { error } = await supabase
    .from('maintenance_complaints')
    .delete()
    .eq('id', id);

  if (error) {
    throw new Error(`Failed to delete complaint ${id}: ${error.message}`);
  }
}

/**
 * Subscribes to realtime Postgres changes on maintenance_complaints.
 */
export function subscribeToComplaints(
  callback: (payload: any) => void
): RealtimeChannel {
  const channel = supabase.channel('complaints-changes');

  channel
    .on(
      'postgres_changes',
      { event: '*', schema: 'public', table: 'maintenance_complaints' },
      (payload) => {
        callback(payload);
      }
    )
    .subscribe();

  return channel;
}
