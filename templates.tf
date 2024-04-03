locals {
  no_sort_key_template  = <<EOF
{
    "status" : "error",
    "message" : "No Sort Key found"
} 
EOF

  get_response_template = <<EOF
#set($inputRoot = $input.path('$'))
{
    "status" : "success",
    "data":[
#foreach($elem in $inputRoot.Items) {
    #foreach($key in $elem.keySet())
    #set($valTypes = $elem.get($key).keySet() )
    #if( $valTypes=="[M]" )
        #set( $nestElem = $elem.get($key).M )
        ##"$key": "$nestElem",
        "$key": {
        #foreach($nKey in $nestElem.keySet())
        #set( $nValTypes = $nestElem.get($nKey).keySet() )
        #if($nValTypes=="[N]")"$nKey": $nestElem.get($nKey).N
        #elseif($nValTypes=="[BOOL]")"$nKey": $nestElem.get($nKey).BOOL
        #else
        "$nKey": "$nestElem.get($nKey).S"
        #end
        #if($foreach.hasNext),#{else}}#end
        #end#if($foreach.hasNext),#end  
    #elseif( $valTypes=="[L]" )
        #set( $nestElem = $elem.get($key).L )
        "$key": [
        #foreach($nItem in $nestElem)
        #set( $nValTypes = $nItem.keySet() )
        #if($nValTypes=="[N]")$nItem.N
        #elseif($nValTypes=="[BOOL]")$nItem.BOOL
        #else
        "$nItem.S"
        #end
        #if($foreach.hasNext),#{else}]#end
        #end#if($foreach.hasNext),#end          
    #elseif( $valTypes=="[SS]" )
        #set( $nestElem = $elem.get($key).SS )
        "$key": [
        #foreach($eachValue in $nestElem)
        "$eachValue"#if($foreach.hasNext),#end
        #end ]#if($foreach.hasNext),#end  
    #elseif( $valTypes=="[NS]" )
        #set( $nestElem = $elem.get($key).NS )
        "$key": [
        #foreach($eachValue in $nestElem)
        $eachValue#if($foreach.hasNext),#end
        #end ]#if($foreach.hasNext),#end  
    #elseif( $valTypes=="[N]" )
    "$key": $elem.get($key).N#if($foreach.hasNext),#end
    #elseif( $valTypes=="[BOOL]" )
    "$key": $elem.get($key).BOOL#if($foreach.hasNext),#end
    #else
    "$key": "$elem.get($key).S"#if($foreach.hasNext),#end
    #end
    #end
}#if($foreach.hasNext),#end
#end
]
}
    EOF
}
