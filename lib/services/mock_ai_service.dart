import '../models/device_guide.dart';

class MockAiService {
  Future<DeviceGuide> analyzeDevice() async {
    await Future.delayed(const Duration(seconds: 2));

    return const DeviceGuide(
      deviceName: 'Máy giặt cửa trước',
      mainFunction: 'Hỗ trợ nhận diện bảng điều khiển và hướng dẫn người dùng chọn chế độ giặt cơ bản.',
      steps: [
        'Cho quần áo vào lồng giặt và đóng cửa máy chắc chắn.',
        'Cho nước giặt vào ngăn chứa theo lượng vừa đủ.',
        'Chọn chế độ giặt nhanh hoặc giặt thường trên bảng điều khiển.',
        'Nhấn nút Start để bắt đầu quá trình giặt.',
      ],
      safetyNote: 'Không mở cửa máy khi máy đang hoạt động. Nếu có lỗi, hãy tắt nguồn trước khi kiểm tra.',
    );
  }
}