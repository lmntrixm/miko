export type WorkType = 'manga' | 'manhwa' | 'comic';
export type Lang = 'fa' | 'en';

export const TYPE_LABEL: Record<WorkType, string> = { manga: 'مانگا', manhwa: 'مانهوا', comic: 'کامیک' };

export interface Title {
  id: string;
  nameFa: string;
  nameEn: string;
  type: WorkType;
  status: 'ongoing' | 'finished' | 'draft';
  genres: string[];
  langs: Lang[];
  chapters: number;
  views: number;
  rating: number | null;
  updatedAt: string;
  author: string;
  weekday: string;
  summary: string;
}

export interface ChapterItem {
  id: string;
  titleId: string;
  number: number;
  titleEn: string;
  date: string;
  langs: Lang[];
  views: number;
  comments: number;
}

export type TaskColumn = 'waiting' | 'translating' | 'review' | 'ready';
export interface Task {
  id: string;
  titleName: string;
  chapter: number;
  direction: string;
  column: TaskColumn;
  assignee: string;
  due: string; // ISO date
  progress?: { done: number; total: number };
  note?: string;
  scheduledAt?: string;
  approvedBy?: string;
}

export interface TitleRequest {
  id: string;
  nameEn: string;
  firstRequested: string;
  votes: number;
  type: WorkType;
  lang: string;
  publishRight: 'has' | 'none' | 'negotiating';
  status: 'open' | 'added' | 'rejected';
}

export type UserStatus = 'active' | 'expired' | 'free' | 'blocked';
export interface User {
  id: string;
  name: string;
  email: string;
  plan: string | null;
  endsIn: number | null; // days
  joined: string;
  chaptersRead: number;
  status: UserStatus;
  prefLang: string;
  devices: { name: string; lastSeen: string; online: boolean }[];
  notes: { text: string; by: string; when: string }[];
  history: { title: string; progress: number; lang: string; when: string }[];
  payments: string[];
}

export interface Plan {
  id: string;
  name: string;
  days: number;
  priceToman: number | null; // null → [قیمت]
  active: boolean;
  subscribers: number;
}
export interface Coupon {
  code: string;
  note: string;
  uses: number;
  expired: boolean;
}
export interface Transaction {
  code: string;
  user: string;
  plan: string;
  date: string;
  gateway: string;
  status: 'success' | 'failed';
}

export interface CommentItem {
  id: string;
  user: string;
  work: string;
  chapter: number;
  when: string;
  body: string;
  tags: ('spoiler' | 'link' | 'spam' | 'insult')[];
  reports: number;
  status: 'reported' | 'pending' | 'approved' | 'deleted';
}

export interface SentNotification {
  id: string;
  title: string;
  audience: string;
  channels: string[];
  sent: number;
  openRate: number;
  when: string;
}

export type AuditSection = 'content' | 'users' | 'payment' | 'settings';
export interface AuditEntry {
  id: string;
  when: string;
  member: string;
  section: AuditSection;
  action: string;
  device: string;
}

export type Role = 'admin' | 'editor' | 'translator' | 'moderator';
export const ROLE_LABEL: Record<Role, string> = { admin: 'مدیر کل', editor: 'ویراستار محتوا', translator: 'مترجم', moderator: 'ناظر نظرات' };
export interface Member {
  id: string;
  name: string;
  role: Role;
  lastSeen: string;
  online?: boolean;
}
export const PERMISSIONS = [
  'افزودن و ویرایش آثار',
  'آپلود چپتر',
  'انتشار و زمان‌بندی',
  'مدیریت کاربران',
  'مشاهده پرداخت‌ها',
  'مدیریت نظرات',
  'ارسال اعلان',
  'تغییر تنظیمات',
] as const;
export type Permission = (typeof PERMISSIONS)[number];
