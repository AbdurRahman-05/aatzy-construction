/**
 * Shared rules for the B2B materials flow (products + material inquiries).
 *
 * Inquiry lifecycle
 *   New / Viewed / Contacted ──(supplier: Quote Sent + price)──► Quote Sent
 *   Quote Sent ──(buyer)──► Accepted | Closed (accepted)  or  Rejected (buyer may get a new quote)
 *   Accepted / Closed ──(supplier: delivery Pending → Packed → Dispatched → Delivered)──► Completed
 *   Accepted / Closed ──(buyer confirms receipt)──► Completed
 *   Lead Rejected (supplier declined) and Completed are final.
 */

/** Product categories, keyed by the id the app sends. Keep in sync with the app's list. */
export const PRODUCT_CATEGORIES: Record<number, string> = {
  1: 'Materials & Supply',
  2: 'Electrical',
  3: 'Plumbing',
  4: 'Interior Design',
  5: 'Furniture',
  6: 'Paints',
  7: 'Hardware',
  8: 'LED Walls & Digital Displays',
};

export function categoryNameFor(categoryId: number | null | undefined, fallback?: string | null): string {
  if (categoryId && PRODUCT_CATEGORIES[categoryId]) return PRODUCT_CATEGORIES[categoryId];
  return fallback || 'Materials & Supply';
}

export function parseCategoryId(value: unknown): number | undefined {
  const n = parseInt(String(value ?? ''), 10);
  return Number.isFinite(n) && PRODUCT_CATEGORIES[n] ? n : undefined;
}

/** Statuses before the buyer has accepted a quote. */
export const PRE_ACCEPT_STATUSES = ['New', 'Viewed', 'Contacted', 'Quote Sent', 'Rejected'];
/** Statuses after the buyer accepted (deal is on, delivery in progress). */
export const ACCEPTED_STATUSES = ['Accepted', 'Closed'];
/** Nothing can change any more. */
export const FINAL_STATUSES = ['Completed', 'Lead Rejected'];

export const DELIVERY_STAGES = ['Pending', 'Packed', 'Dispatched', 'Delivered'];

export interface InquiryState {
  status: string;
  quotedPrice: number | null;
  deliveryStatus: string;
}

export type RuleResult = { ok: true } | { ok: false; error: string; code: string };

const deny = (error: string, code = 'INVALID_INQUIRY_TRANSITION'): RuleResult => ({ ok: false, error, code });
const allow: RuleResult = { ok: true };

/** What the supplier may change on a lead. */
export function checkSupplierUpdate(
  current: InquiryState,
  change: { status?: string; quotedPrice?: number; gstPercent?: number; deliveryStatus?: string }
): RuleResult {
  const { status, quotedPrice, gstPercent, deliveryStatus } = change;

  if (FINAL_STATUSES.includes(current.status)) {
    return deny('This order is already finished and cannot be changed.', 'INQUIRY_FINAL');
  }

  if (status === 'Accepted' || status === 'Rejected') {
    return deny('Only the buyer can accept or decline a quote.');
  }

  const accepted = ACCEPTED_STATUSES.includes(current.status);

  if (accepted) {
    if (quotedPrice !== undefined || gstPercent !== undefined) {
      return deny('The price is locked because the buyer already accepted this quote.', 'QUOTE_LOCKED');
    }
    if (status && !['Closed', 'Completed'].includes(status)) {
      return deny(`Cannot move an accepted order to "${status}".`);
    }
    if (deliveryStatus !== undefined && !DELIVERY_STAGES.includes(deliveryStatus)) {
      return deny('Unknown delivery stage.');
    }
    const finalDelivery = deliveryStatus ?? current.deliveryStatus;
    if (status === 'Completed' && finalDelivery !== 'Delivered') {
      return deny('Mark the material as Delivered before completing the order.');
    }
    return allow;
  }

  // Before the buyer accepts
  if (deliveryStatus !== undefined && deliveryStatus !== current.deliveryStatus) {
    return deny('Delivery can only be updated after the buyer accepts your quote.');
  }
  if (status && !['Viewed', 'Contacted', 'Quote Sent', 'Lead Rejected'].includes(status)) {
    return deny(`Cannot move this inquiry to "${status}" before the buyer accepts a quote.`);
  }
  if (quotedPrice !== undefined && !(quotedPrice > 0)) {
    return deny('Enter a valid price per unit.');
  }
  if (gstPercent !== undefined && !(gstPercent >= 0 && gstPercent <= 28)) {
    return deny('GST must be between 0% and 28%.');
  }
  if (status === 'Quote Sent' && !((quotedPrice ?? current.quotedPrice ?? 0) > 0)) {
    return deny('Add a price before sending the quote.');
  }
  return allow;
}

/** What the buyer may change on their inquiry. */
export function checkBuyerUpdate(
  current: InquiryState,
  change: { status?: string; rating?: number }
): RuleResult {
  const { status, rating } = change;

  if (status) {
    if (status === 'Accepted' || status === 'Closed' || status === 'Rejected') {
      if (current.status !== 'Quote Sent' || !(current.quotedPrice && current.quotedPrice > 0)) {
        return deny('There is no quote to respond to yet.');
      }
    } else if (status === 'Completed') {
      if (!ACCEPTED_STATUSES.includes(current.status) && current.status !== 'Completed') {
        return deny('You can confirm delivery only after accepting a quote.');
      }
    } else {
      return deny(`Cannot change this inquiry to "${status}".`);
    }
  }

  if (rating !== undefined) {
    if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
      return deny('Rating must be between 1 and 5 stars.', 'INVALID_RATING');
    }
    const finalStatus = status ?? current.status;
    if (finalStatus !== 'Completed') {
      return deny('You can rate the supplier after the material is delivered.', 'INVALID_RATING');
    }
  }
  return allow;
}
