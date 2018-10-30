import 'dart:async';
import 'package:breez/bloc/account/account_bloc.dart';
import 'package:breez/bloc/account/account_model.dart';
import 'package:breez/bloc/app_blocs.dart';
import 'package:breez/bloc/bloc_widget_connector.dart';
import 'package:breez/widgets/static_loader.dart';
import 'package:flutter/material.dart';
import 'package:breez/theme_data.dart' as theme;
import 'package:breez/widgets/back_button.dart' as backBtn;
import 'package:breez/widgets/amount_form_field.dart';
import 'package:breez/bloc/invoice/invoice_bloc.dart';
import 'package:breez/bloc/invoice/invoice_model.dart';
import 'package:breez/routes/user/create_invoice/qr_code_dialog.dart';

class CreateInvoicePage extends StatelessWidget {
  CreateInvoicePage();

  @override
  Widget build(BuildContext context) {
    return new BlocConnector<AppBlocs>((context, blocs) =>
        _CreateInvoicePage(blocs.accountBloc, blocs.invoicesBloc));
  }
}

class _CreateInvoicePage extends StatefulWidget {
  final AccountBloc _accountBloc;
  final InvoiceBloc _invoiceBloc;

  const _CreateInvoicePage(this._accountBloc, this._invoiceBloc);

  @override
  State<StatefulWidget> createState() {
    return new _CreateInvoiceState();
  }
}

class _CreateInvoiceState extends State<_CreateInvoicePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController =
      new TextEditingController();
  final TextEditingController _amountController = new TextEditingController();
  StreamSubscription<bool> _paidInvoicesSubscription;

  @override
  void initState() {
    super.initState();
    _paidInvoicesSubscription =
        widget._invoiceBloc.paidInvoicesStream.listen((paid) {
      Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _paidInvoicesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String _title = "Create an Invoice";
    return new Scaffold(
      bottomNavigationBar: new Padding(
          padding: new EdgeInsets.only(bottom: 40.0),
          child: new Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            new SizedBox(
              height: 48.0,
              width: 168.0,
              child: StreamBuilder<AccountModel>(
                  stream: widget._accountBloc.accountStream,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return StaticLoader();
                    }
                    var account = snapshot.data;
                    return RaisedButton(
                      padding: EdgeInsets.only(
                          top: 16.0, bottom: 16.0, right: 39.0, left: 39.0),
                      child: new Text(
                        "CREATE",
                        style: theme.buttonStyle,
                      ),
                      color: Colors.white,
                      elevation: 0.0,
                      shape: new RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(42.0)),
                      onPressed: () {
                        if (_formKey.currentState.validate()) {
                          widget._invoiceBloc.newStandardInvoiceRequestSink.add(
                              new InvoiceRequestModel(
                                  null,
                                  _descriptionController.text,
                                  null,
                                  account.currency
                                      .parse(_amountController.text)));
                          showDialog(
                              context: context, builder: (_) => QrCodeDialog(context, widget._invoiceBloc));
                        }
                      },
                    );
                  }),
            )
          ])),
      appBar: new AppBar(
        iconTheme: theme.appBarIconTheme,
        textTheme: theme.appBarTextTheme,
        backgroundColor: Color.fromRGBO(5, 93, 235, 1.0),
        leading: backBtn.BackButton(),
        title: new Text(_title, style: theme.appBarTextStyle),
        elevation: 0.0,
      ),
      body: StreamBuilder<AccountModel>(
        stream: widget._accountBloc.accountStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return StaticLoader();
          }
          AccountModel acc = snapshot.data;
          return Form(
            key: _formKey,
            child: new Padding(
              padding: EdgeInsets.only(
                  left: 16.0, right: 16.0, bottom: 40.0, top: 24.0),
              child: new Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new TextFormField(
                    controller: _descriptionController,
                    decoration: new InputDecoration(
                      labelText: "Description",
                    ),
                    style: theme.FieldTextStyle.textStyle,
                    validator: (text) {
                      if (text.length == 0) {
                        return "Please enter a description";
                      }
                    },
                  ),
                  new AmountFormField(
                      controller: _amountController,
                      currency: acc.currency,
                      maxAmount: acc.maxAllowedToReceive,
                      decoration: new InputDecoration(
                          labelText: acc.currency.displayName + " Amount"),
                      style: theme.FieldTextStyle.textStyle),
                  new Container(
                    padding: new EdgeInsets.only(top: 36.0),
                    child: _buildReceivableBTC(acc),
                  ),
                  StreamBuilder(
                      stream: widget._accountBloc.accountStream,
                      builder: (BuildContext context,
                          AsyncSnapshot<AccountModel> accSnapshot) {

                        AccountModel acc = accSnapshot.data;

                        String message;
                        if (accSnapshot.hasError) {
                          message = accSnapshot.error.toString();
                        } else if (!accSnapshot.hasData) {
                          message =
                              'Receiving payments will be available as soon as Breez is synchronized.';
                        } else if (acc.waitingDepositConfirmation || acc.processiongBreezConnection) {
                          message =
                              'You will be able to receive payments after Breez is finished opening a secure channel with our server. This usually takes ~10 minutes to be completed. Please try again in a couple of minutes.';
                        }

                        if (message != null) {
                          // In case error doesn't have a trailing full stop
                          if (!message.endsWith('.')) {
                            message += '.';
                          }
                          return Container(
                              padding: EdgeInsets.only(
                                  top: 50.0, left: 30.0, right: 30.0),
                              child: Column(children: <Widget>[
                                Text(
                                  message,
                                  textAlign: TextAlign.center,
                                ),
                              ]));
                        }
                        else {
                          return Container();
                        }
                      })
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceivableBTC(AccountModel acc) {
    return new Row(
      children: <Widget>[
        new Text("Receive up to:", style: theme.textStyle),
        new Padding(
          padding: EdgeInsets.only(left: 3.0),
          child: new Text(acc.currency.format(acc.maxAllowedToReceive),
              style: theme.textStyle),
        )
      ],
    );
  }
}