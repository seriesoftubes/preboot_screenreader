#include <opencv2/opencv.hpp>

// Avoiding name mangling
extern "C"
{
	// Attributes to prevent 'unused' function from being removed and to make it visible
	__attribute__((visibility("default"))) __attribute__((used))
	const char* version()
	{
		return CV_VERSION;
	}

	__attribute__((visibility("default"))) __attribute__((used))
	std::vector<std::vector<double>> detect_squares(cv::Mat* img)
	{
		// Minimum rectangle area
		double min_area = (img.cols / 3) * (img.rows / 3);

		// Convert RGB to Grayscale
		cv::Mat gray;
		cv::cvtColor(img, gray, cv::COLOR_BGR2GRAY);

		// Blur the image with 5x5 Gaussian kernel
		cv::Mat blur;
		cv::GaussianBlur(gray, blur, cv::Size(5, 5), 1);

		// Canny Edge Detection
		cv::Mat canny;
		cv::Canny(blur, canny, 10, 50);

		// Find contours
		std::vector<std::vector<cv::Point>> contours;
		cv::findContours(canny, contours, cv::RETR_TREE, cv::CHAIN_APPROX_SIMPLE);

		// Find rectangles
		std::vector<std::vector<double>> rect_array;
		for (int i = 0; i < contours.size(); i++)
		{
			cv::Rect rect = cv::boundingRect(cv::Mat(contours[i]));
			if (rect.width < 300 or rect.height < 300)
			{
				continue;
			}
			double area = cv::contourArea(cv::Mat(contours[i]));
			if (area >= min_area)
			{
				double x1 = rect.x;
				double y1 = rect.y;
				double x2 = rect.x + rect.width;
				double y2 = rect.y + rect.height;

				std::vector<double> points{x1, y1, x2, y2};
				rect_array.push_back(points);
			}
		}
		return rect_array;
	}
}