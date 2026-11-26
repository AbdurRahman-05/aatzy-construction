import {
  Activity,
  Columns3,
  HardHat,
  Inbox,
  LayoutGrid,
  Megaphone,
  Package,
  Users,
  type LucideIcon,
} from 'lucide-react';

export interface NavItem {
  id: string;
  label: string;
  title: string;
  subtitle: string;
  icon: LucideIcon;
  group: 'Run' | 'People' | 'Marketplace' | 'System';
}

export const NAV_ITEMS: NavItem[] = [
  { id: 'dashboard', label: 'Overview', title: 'Overview', subtitle: 'How Connectzy is doing right now', icon: LayoutGrid, group: 'Run' },
  { id: 'pending', label: 'Approvals', title: 'Approvals inbox', subtitle: 'New partners and products waiting for you', icon: Inbox, group: 'Run' },
  { id: 'projects', label: 'Projects', title: 'Projects board', subtitle: 'Every project by stage - spot what is stuck', icon: Columns3, group: 'Run' },
  { id: 'users', label: 'Customers', title: 'Customers', subtitle: 'People building and renovating with Connectzy', icon: Users, group: 'People' },
  { id: 'providers', label: 'Partners', title: 'Partners', subtitle: 'Contractors, suppliers and service providers', icon: HardHat, group: 'People' },
  { id: 'products', label: 'Products', title: 'Material products', subtitle: 'Everything partners sell in the materials market', icon: Package, group: 'Marketplace' },
  { id: 'ads', label: 'Ads', title: 'Ads & banners', subtitle: 'What customers and partners see on the home screen', icon: Megaphone, group: 'Marketplace' },
  { id: 'recent-actions', label: 'Activity', title: 'Activity', subtitle: 'Everything that happened across the platform', icon: Activity, group: 'System' },
];

export function navFor(view: string): NavItem {
  return NAV_ITEMS.find(n => n.id === view) ?? NAV_ITEMS[0];
}

export const THEME_COOKIE = 'cz_admin_theme';
export const SIDEBAR_COOKIE = 'cz_admin_sidebar';

export function setPrefCookie(name: string, value: string) {
  document.cookie = `${name}=${value}; path=/; max-age=31536000; samesite=lax`;
}

export interface SearchIndex {
  users: { id: string; name: string; email: string; phone: string }[];
  providers: { id: string; name: string; owner: string; phone: string; email: string; category: string; verified: boolean }[];
  projects: { id: string; title: string; location: string; client: string; stage: string }[];
}
