import { supabase } from './maintenanceService';

export type NozzleName = 'A1' | 'A2' | 'B1' | 'B2';
export type ManualStatus = 'okay' | 'shortage' | 'excess';

export interface DenominationBreakdown {
  500?: number;
  200?: number;
  100?: number;
  50?: number;
  20?: number;
  10?: number;
  coins?: number;
  [key: string]: number | undefined;
}

export interface CashVerificationNozzleInput {
  nozzle_name: NozzleName;
  opening_reading: number;
  closing_reading: number;
  card_amount: number;
  upi_amount: number;
  other_exp_amount: number;
  other_exp_remark?: string;
  denominations: DenominationBreakdown;
  cash_total: number;
  difference: number;
}

export interface CashVerificationHeaderInput {
  id?: string;
  site_id: 'OWP' | 'TPT' | 'WIM' | string;
  entry_date: string;
  entry_time: string;
  manual_status: ManualStatus;
  total_sales: number;
  total_cash: number;
  total_card: number;
  total_upi: number;
  total_other_exp: number;
  net_difference: number;
  remarks?: string;
}

export interface CashVerificationRecord extends CashVerificationHeaderInput {
  id: string;
  created_at: string;
  updated_at: string;
  cash_verification_nozzles?: CashVerificationNozzleInput[];
}

/**
 * Submits a cash verification entry:
 * Inserts the header into cash_verifications, retrieves the verification ID,
 * and inserts 4 nozzle records (A1, A2, B1, B2) within a single logical flow.
 */
export async function submitCashVerification(
  headerData: CashVerificationHeaderInput,
  nozzlesArray: CashVerificationNozzleInput[]
): Promise<{ header: any; nozzles: any[] }> {
  // 1. Insert header
  const { data: header, error: headerErr } = await supabase
    .from('cash_verifications')
    .insert({
      ...headerData,
      manual_status: headerData.manual_status || 'okay',
    })
    .select()
    .single();

  if (headerErr || !header) {
    throw new Error(`Failed to insert cash verification header: ${headerErr?.message}`);
  }

  const verificationId = header.id;

  // 2. Prepare and insert 4 nozzle records
  const nozzleRows = nozzlesArray.map((nozzle) => ({
    verification_id: verificationId,
    nozzle_name: nozzle.nozzle_name,
    opening_reading: nozzle.opening_reading,
    closing_reading: nozzle.closing_reading,
    card_amount: nozzle.card_amount,
    upi_amount: nozzle.upi_amount,
    other_exp_amount: nozzle.other_exp_amount,
    other_exp_remark: nozzle.other_exp_remark || null,
    denominations: nozzle.denominations || {},
    cash_total: nozzle.cash_total,
    difference: nozzle.difference,
  }));

  const { data: nozzles, error: nozzlesErr } = await supabase
    .from('cash_verification_nozzles')
    .insert(nozzleRows)
    .select();

  if (nozzlesErr) {
    throw new Error(`Failed to insert nozzle shift records: ${nozzlesErr.message}`);
  }

  return { header, nozzles };
}

/**
 * Fetches verification history joined with nozzle records.
 */
export async function fetchVerificationHistory(
  siteId?: string
): Promise<CashVerificationRecord[]> {
  let query = supabase
    .from('cash_verifications')
    .select('*, cash_verification_nozzles(*)');

  if (siteId && siteId !== 'ALL') {
    query = query.eq('site_id', siteId);
  }

  const { data, error } = await query
    .order('created_at', { ascending: false })
    .limit(50);

  if (error) {
    throw new Error(`Failed to fetch verification history: ${error.message}`);
  }

  return (data as CashVerificationRecord[]) || [];
}
