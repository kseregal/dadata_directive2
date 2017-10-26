# ��������� ��� ���������� material-auto-suggest-input �� ������ angular_components.

��������� DadataDirective ��������� ���������

* ������
* ���������� �����������
* ���������� �����
* ���
* email

## ��� ������������
 ������������ ��� ���������� material_auto_suggest_input.
 ### ������:
 ```
 <material-auto-suggest-input
  dadata="legal_entity"
  [gender]="gender"
  dadata-delay="500"
  dadata-token="ksdfjwoefjweoo"
</material-auto-suggest-input>
```
  dadata="legal_entity" - � �������� ��������� ��������� �������� ������������� ���������
  * address - ������������� �������.
  * city - ����� ������. 
  * surname - ������������� �������.
  * name - ������������� ����.
  * patronymic - ������������� �������.
  * fio - ������������� ������� ���� � �������.
  * bank - �� ���������� �����.
  * legal_entity - �� ���������� �����������.

 ������ ���������, ������� �����, ��������� � ���� � ��������� ��������� � �������
 dadata.ru �� ������� ���������.
 ��������� � ������� ���������� ����������� http ������� � REST API.
 ��������� �������� ������������ ����� �������� ���������, ��������� �������������������.
 ����� � ������ ������� �������� ��������, ����������� � ����� �������������������.
 ��� ��������� ������������������� ��� ������ ������� �������� ��������� ���������� ������ �
 dadata.ru � ����� ����������� ����������. ��������� ���������� ���������� �����
 ������ ��� ��������� ������������� �������� �����.
 ����� ����� ������������ � ������ ��������� � dadata.ru. ��� �� ������������, ����
 �� ������� ����������.

 ������� ��������� ��� ����� ����������� �����.
 � ����� ������ ��������� ������ �������� � ������������ � �����.
 ������ ��������� �������� �������� gender ���.
 MALE, FEMALE ��� UNKNOWN
 
 UNKNOWN - ����� ������� ��������� �������� � �������� ��������. �������� �������.

 ���� � ���������, ���������� material-auto-suggest, �������� ��������� �������� gender,
 �� ��� �������� ����� �������� � ���������.
 ���� ��� �������� �� null, �� ��������� ����� ������������ ��� �������� ���
 ��������� ������ ���������.
 
 ��� ����� �������� ������ � ����� ������. ��� ���������� � ������
 ```
 <material-auto-suggest-input
  ...
  [gender]="gender"
  ...
</material-auto-suggest-input>
```
 ���������, ���������� material-auto-suggest-input, ����� ������ ������
 ```
 (blur)="method()"
 ```
 ���������� SelectionModel, �������� �������� gender, � ��������� �������� ����������
 gender.
 
 !�����! ������ ���� ������ ��� [gender]="gender".

```
<material-auto-suggest-input
  ...
  dadata-delay="500"
  ...
</material-auto-suggest-input>
```

 �������� delay ������ ��� ��������� �������� ���������� ������� � ������������
 ���� ������������ ������ �� ����������.
 ���� �������� �� ���������, �� ������������ ���������� �������� 500.

 * dadata-token - ������������ ��������. �������� ����� ����������� �� ������� dadata.ru.
 
 ��������� ��������� ��������� 1000 �������� � �����.