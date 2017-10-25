import 'dart:async';
import 'dart:convert';
import 'package:http/browser_client.dart';
import 'package:angular/angular.dart';
import 'package:angular_components/material_input/material_auto_suggest_input.dart';
import 'package:angular_components/model/selection/selection_options.dart';

/// ## Директива автоподсказок сервиса dadata.ru
///
/// Используется для компонента material_auto_suggest_input.
/// ### Пример:
/// ```
/// <material-auto-suggest-input
///  dadata="legal_entity"
///  [gender]="gender"
///  dadata_delay="500"
///  dadata_token="ksdfjwoefjweoo"
///</material-auto-suggest-input>
///```
///  dadata="legal_entity" - в кавычках указываем возможные варианты использования подсказок
///  * address - автоподсказка адресов.
///  * surname - автоподсказка фамилий.
///  * name - автоподсказка имен.
///  * patronymic - автоподсказка отчеств.
///  * fio - автоподсказка фамилий имен и отчеств.
///  * bank - по реквизитам банка.
///  * legal_entity - по реквизитам организации.
///
/// Задача директивы, получив текст, введенный в поле и выполнить обращение к сервису
/// dadata.ru за списком подсказок.
/// Обращение к сервису происходит посредством http запроса к REST API.
/// Некоторые варианты использоваия могут выдавать подсказки, используя геопозиционирование.
/// Тогда в первую очередь выдаются варианты, относящиеся к месту геопозиционирования.
/// Для получения геопозиционирования при первой попытке получить подсказку происходит запрос к
/// dadata.ru с целью определения геопозиции. Директива запоминает полученный КЛАДР
/// города или состояние невозможности получить КЛАДР.
/// Затем КЛАДР используется в каждом обращении к dadata.ru. Или не используется, если
/// не удалось определить.
///
/// Запросы подсказок ФИО могут дополняться полом.
/// В таком случае подсказка выдает варианты в соответствии с полом.
/// Каждая подсказка содержит параметр gender пол.
/// MALE, FEMALE или UNKNOWN
/// UNKNOWN - такой вариант возникает например в бесполых фамилиях. Например Редекоп.
///
/// Если в компонент, содержащий material-auto-suggest, добавить публичное свойство gender,
/// то это свойство будет доступно в директиве.
/// Если это свойство не null, то директива будет использовать это свойство при
/// получении списка подсказок.
/// Это будет работать только в одном случае. При добавлении в шаблон
/// ```
/// <material-auto-suggest-input
///  ...
///  [gender]="gender"
///  ...
///</material-auto-suggest-input>
///```
/// Компонент, содержащий material-auto-suggest-input, может внутри метода
/// ```
/// (blur)="method()"
/// ```
/// обработать SelectionModel, получить значение gender, и присвоить свойству компонента
/// gender.
/// !Важно! Должно быть только так [gender]="gender".
///
/// ```<material-auto-suggest-input
///  ...
///  dadata_delay="500"
///  ...
///</material-auto-suggest-input>```
///
/// Параметр delay задает для директивы задержку выполнения запроса в миллисекунда
/// пока пользователь стучит по клавиатуре.
/// Если параметр не определен, то используется дефолтовое значение 500.
///
/// * dadata_token - обязательный параетр. Содержит токен.
///
@Directive(selector: '[dadata]')
class DadataDirective {
  /// Основной url для получения подсказок.
  String _baseSuggestUrl = "https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/";
  /// url для определения геопозиционирования.
  String _detectAddressByIpUrl = 'https://suggestions.dadata.ru/suggestions/api/4_1/rs/detectAddressByIp?';
  final MaterialAutoSuggestInputComponent _suggestElem;
  BrowserClient _client = new BrowserClient();
  /// Пол. Переменная для внутреннего использования.
  String _gender = 'UNKNOWN';
  /// Параметр, определяющий тип запроса к dadata.
  /// Тип запроса может быть address, legal_entity, bank, fio, surname, name, patronymic
  String _queryType = null;

  /// Список вариантов использованвия dadata, где
  /// учитывается местонахождение (геолокация до города).
  List<String> useGeoLocationWith = const[ 'address', 'legal_entity', 'bank' ];

  @Input("dadata_token")
  String token;

  /// Заголовки для работы с API dadata
  Map<String,String> _requestHeaders;
  /// КЛАДР. Используется для сортировки подсказок в соответствии с геолокацией.
  String kladrId = null;

  DadataDirective(this._suggestElem) {

    /// Пустой список. Без этого работать не будет.
    _suggestElem.options = new SelectionOptions( [new OptionGroup<String>([])]);

  }

  @Input("dadata_delay")
  String delay;

  /// Пол. Определяется как свойство компонента.
  @Input()
  String gender;

  /// Вариант автоподсказки.
  @Input()
  String dadata;

  /// Храним здесь введенный текст.
  String _inputText;

  /// Таймер отсчитывает DadataConfig.delay и выполняет callback
  Timer _timer=null;

  startTimeout() {
    delay = delay ?? 500;
    return new Timer(new Duration(milliseconds: int.parse(delay)), getSelectionOptions);
  }

  /// Колбэк таймера, который выполняет запрос к dadata.
  getSelectionOptions() {
    /// Преобразуем параметр пола, полученный через @Input к виду, необходимому для
    /// использования в сервисе dadata.ru
    _gender = ( gender!=null ) ? gender.toUpperCase(): "UNKNOWN";
    _queryType = dadata.toLowerCase();
    
    Map requestBody = {
      "query": _inputText
    };
    /// Для подсказки ФИО не важен город. Поэтому locations_boost в этом случае
    /// в запросе не указываем.
    if ( useGeoLocationWith.contains(_queryType)  &&
        kladrId != null ) {
      requestBody["locations_boost"] = [{"kladr_id": kladrId}];
    }

    String url = null;

    switch (_queryType) {
      case 'address':
        url = "${_baseSuggestUrl}address";
        break;
      case 'surname':
      case 'name':
      case 'patronymic':
        /// Определяем, какую часть подсказки ФИО нам нужна: Фамилия, Имя или Отчество.
        requestBody["parts"] = [_queryType.toUpperCase()];
        /// Если пол определен, то получаем подсказки с учетом пола.
        if ( _gender !=null && (_gender=='MALE' || _gender=='FEMALE') ) {
          requestBody["gender"] = _gender;
        }
        url = "${_baseSuggestUrl}fio";
        break;
      case 'fio':
        url = "${_baseSuggestUrl}fio";
        break;
      case 'legal_entity':
        url = "${_baseSuggestUrl}party";
        break;
      case 'bank':
        url = "${_baseSuggestUrl}bank";
        break;
      case 'email':
        url = "${_baseSuggestUrl}email";
        break;
    }



    _client.post(
        url,
        headers: _requestHeaders,
        body: JSON.encode(requestBody))
        .then((response) {
      Map resBody = JSON.decode(response.body);
      List<Map<String, String>> suggList =  resBody["suggestions"];
      _suggestElem.options = new SelectionOptions([new OptionGroup(suggList)]);
    });

  }

  _getKladr () async {
    _requestHeaders = {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "Authorization": "Token ${token}"
    };
    /// Получение КЛАДР. Здесь Dadata делает геолокацию по IP адресу.
    await _client.get( _detectAddressByIpUrl, headers: _requestHeaders)
        .then((response) {
          Map resBody = JSON.decode(response.body);
          if (resBody['location']['data'] != null && resBody['location']['data'].containsKey('kladr_id')) {
            kladrId = resBody['location']['data']['kladr_id'];
          } else {
            /// Не удалось определить kladr_id. Больше не пытаемся.
            kladrId = 'undef';
          }
        });
  }

  @HostListener('inputTextChange', const [r'$event'])
  void inputTextChange(String autoSugText) {
    if ( kladrId==null ) _getKladr();
    _inputText = autoSugText;

    if (_timer!=null && _timer.isActive) {
      _timer.cancel();
    }

    _timer = startTimeout();
  }
}