import axios from 'axios';

export function errorMessage(error: unknown, fallback = 'Không tải được dữ liệu. Vui lòng thử lại.') {
  if (axios.isAxiosError(error)) {
    const message = error.response?.data?.message;
    if (Array.isArray(message)) return message.join('. ');
    if (typeof message === 'string') return message;
  }
  return fallback;
}
