/** Same error shape for every failure: a stable code + a Persian cause-and-fix message. */
export class ApiError extends Error {
  constructor(public status: number, public code: string, message: string) {
    super(message);
  }
}

export const errors = {
  unauthorized: () => new ApiError(401, 'unauthorized', 'نشست شما منقضی شده است. دوباره وارد شوید.'),
  paymentRequired: () => new ApiError(402, 'subscription_required', 'این چپتر نیاز به اشتراک دارد.'),
  deviceLimit: () => new ApiError(409, 'device_limit', 'دانلود فقط روی ۲ دستگاه ممکن است. یکی از دستگاه‌ها را حذف کنید.'),
  notFound: () => new ApiError(404, 'not_found', 'پیدا نشد.'),
  invalid: (msg = 'اطلاعات واردشده درست نیست.') => new ApiError(400, 'invalid', msg),
  tooMany: () => new ApiError(429, 'too_many_attempts', 'تلاش‌های ناموفق زیاد بود. چند دقیقه بعد دوباره امتحان کنید.'),
};
