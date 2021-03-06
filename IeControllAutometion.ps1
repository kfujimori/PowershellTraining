############################################################################
# 以下、定数を定義
############################################################################

# 何かの理由で再実行した際に、定数を上書きすることになって例外が出るので、それをもみ消す
$ErrorActionPreference = "Stop"
try {

    set USER_ID "foo" -option constant
    set PASSWORD "bar" -option constant

}catch [Exception] {
    Write-Host "定数宣言で例外が出ましたがもみ消して処理を継続します。"
}
$ErrorActionPreference = "Continue"











############################################################################
# 以下、関数群を定義
# メイン処理は下部を参照
############################################################################


######################################
# 処理継続ダイアログを表示
# ダイアログに表示するメッセージを引数として受け取る
# y or Y が入力された場合は処理を継続
# それ以外の場合は処理を強制終了
######################################
function PushConfirmDialog($message) {

    $message = $message + " 処理を継続してよければ y と入力してください"
    # ユーザ入力受付
    # キャンセルボタンが押下された場合は自動で強制終了
    $input = Read-Host $message

    if(($input -eq "y") -Or($input -eq "Y")){
        Write-Host "処理を継続します"
    } else {
        Write-Host "処理を終了します"
        
        ##########
        # 強制終了
        ##########
        exit
    }
}

######################################
# 一定のルールで標準出力
# 出力したいメッセージを引数として受け取る
######################################
function WriteConsoleLog($message) {

    Write-Host "######################################"
    Write-Host $message
    Write-Host "######################################"
}


######################################
# HTML上の特定IDのエレメントを取得
######################################
function GetElementById($id) {

    $doc = $ie.Document

    $element = [System.__ComObject].InvokeMember(
            "getElementById"                                    # 指定方法にIDを使用
            ,[System.Reflection.BindingFlags]::InvokeMethod     # おまじない
            , $null                                             # 不要パラメータ
            , $doc                                              # ページ情報オブジェクト
            , $id                                               # ID名
            )
            
    return $element
}


######################################
# HTML上の特定Tag、特定InnnerText or name のエレメントを取得
######################################
function GetElementByTagName($tag, $text) {

    $element = $ie.Document.getElementsByTagName($tag) |
                    where-object {
                        $_.name -eq $text
                    }
    
    if ($null -eq $element) {
        $element = $ie.Document.getElementsByTagName($tag) |
                        where-object {
                            $_.innerText -eq $text
                        }
    }
            
    return $element
}














############################################################################
# 以下、メイン処理
############################################################################



# 削除するデータの範囲の指定（ユーザ入力を受け付けるダイアログ表示）
$limit = Read-Host "yyyy/mm/dd形式で値を入力してください。入力された日付よりも古い期限切れデータを削除します。"

$message = "削除日が " + $limit + " よりも過去のデータを削除します"

# 定義済み関数呼び出し（処理の継続確認用）
PushConfirmDialog $message

WriteConsoleLog $message


#######################
# IE起動と画面表示
#######################
$ie = New-Object -ComObject InternetExplorer.Application            # IE起動
$ie.Navigate("https://hoge.com/login")    # URL指定
$ie.Visible = $true                                                 # 表示






# ブラウザ上のコンテンツロード完了待ち
While($ie.Busy)
{ Start-Sleep -s 1 }    


WriteConsoleLog "IEの起動が完了しました"



# ID入力
$element = GetElementById "user_id" 
$element.value = $USER_ID

# パスワード入力
$element = GetElementById "password" 
$element.value = $PASSWORD



# ログインボタン押下
$element = GetElementByTagName "Input" "login_button"
$element.click();




# ブラウザ上のコンテンツロード完了待ち
While($ie.Busy)
{ Start-Sleep -s 1 }    















WriteConsoleLog "ログインが完了しました"
# 定義済み関数呼び出し（処理の継続確認用）
PushConfirmDialog "現状のHDD使用状況をどこかにひかえてください。"











# オプションタブ押下
$element = GetElementById "optionTab"
$element.click();



While($ie.Busy)
{ Start-Sleep -s 1 }    

# 非同期処理のためかロード完了を検知できないので雑に３秒待機
Start-Sleep -s 3


WriteConsoleLog "オプションタブを表示しました"


# 削除管理画面へのリンク押下
$element = GetElementByTagName "A" "削除データ管理"
$element.click();


While($ie.Busy)
{ Start-Sleep -s 1 }    

# 非同期処理のためかロード完了を検知できないので雑に15秒待機
Start-Sleep -s 15

WriteConsoleLog "削除データ管理画面へ遷移しました"


# 削除日時でソート
$element = GetElementByTagName "td" "削除日時"
$element.click();



While($ie.Busy)
{ Start-Sleep -s 1 }    


# 非同期処理のためかロード完了を検知できないので雑に15秒待機
Start-Sleep -s 15




WriteConsoleLog "削除日時でソートしました"



############################ ループしながら削除削除削除 ##############################

WriteConsoleLog "これより先、ループ処理にて削除を繰り返し実行していきます"

while(1 -eq 1) {

# 冒頭で指定した削除期限文字列の検索
$element = $ie.Document.getElementsByTagName('td') |
                where-object {
                    $_.innerText -match $limit
                }
Write-Host $element.Count

# 削除日がリミットまで来たら脱出
if($element.Count -gt 0) {
    break
}












# 全選択ボタン押下
$element = GetElementById "all_bt"
$element.click();

Start-Sleep -s 3


#####################################
# JSの"window.confirm"をオーバーライド
#####################################
$jsCommand = @"
    window.confirm = (function() {
        var nativeConfirm = window.confirm;
        function confirmOnce(message) {
            window.confirm = nativeConfirm;
            return true;
        }
        return confirmOnce;
    })();
"@

$document = $ie.document
$window = $document.parentWindow
$window.execScript($jsCommand, 'javascript') | Out-Null


#####################################
# JSの"window.alert"をオーバーライド
#####################################
$jsCommand = @"
    window.alert = (function() {
        var nativeAlert = window.alert;
        function alertOnce(message) {
            window.alert = nativeAlert;
            return true;
        }
        return alertOnce;
    })(); 
"@

$document = $ie.document
$window = $document.parentWindow
$window.execScript($jsCommand, 'javascript') | Out-Null


# 一括削除ボタン押下
$element = $ie.Document.getElementsByTagName('p') |
                where-object {
                    $_.innerText -match '一括' -And $_.innerText -match '削除'
                }
$element.click()


# 非同期処理のためかロード完了を検知できないので雑に10秒待機
Start-Sleep -s 10


WriteConsoleLog "削除しました。処理を継続します（所定の日付まで来た場合は、ここでループを抜けます"


}
############################ ループしながら削除削除削除 ##############################

WriteConsoleLog "ループを抜けました。処理はすべて完了しました。"










