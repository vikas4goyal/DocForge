import 'package:doc_scanly/app/screens/home_refresh.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a library change notifies Home with no route going away', () {
    final observer = HomeRefreshObserver();
    addTearDown(observer.dispose);
    var notifications = 0;
    observer.addListener(() => notifications++);

    observer.libraryChanged();

    expect(notifications, 1);
  });
}
