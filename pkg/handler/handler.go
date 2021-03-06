package handler

import (
	"chain-web/pkg/model"
	"chain-web/pkg/response"
	"chain-web/pkg/sign"
	"crypto/md5"
	"fmt"
	"github.com/gin-gonic/gin"
)
import . "chain-web/pkg/nt"

//通过用户手机号码+身份证号码+EID编码
func CreateChainAddress(c *gin.Context) {
	if !sign.VerifySign(c) {
		response.FailWithMessage("验签失败", c)
		return
	}
	var user model.User
	user.Phone = c.PostForm("phone")
	user.IdCard = c.PostForm("id_card")
	user.Eid = c.PostForm("eid")
	//TODO 生成一个伪地址保存到数据库里面
	user.FakeChainAddr = fmt.Sprintf("%x", md5.Sum([]byte(user.Phone+user.IdCard+user.Eid)))
	err := user.Insert()
	if err != nil {
		response.FailWithMessage("数据保存失败", c)
	} else {
		response.Ok(c)
	}
}

//通过“用户手机号”，到“全民数据链”--即国金公链 查询得到用户真实的区块链地址，存到数据库中 chain_addr: 区块链地址 中
func SyncNt(c *gin.Context) {
	if !sign.VerifySign(c) {
		response.FailWithMessage("验签失败", c)
		return
	}
	phone := c.PostForm("phone")
	result := GetNtUserDetailResp(phone)
	if result.Code == 0 {
		var user model.User
		user.ChainAddr = result.Data["chain_addr"]
		user.SpaceUsed = result.Data["space_used"]
		_, error := user.Update(phone)
		if error != nil {
			response.FailWithMessage("更新数据失败", c)
		} else {
			response.OkWithData(result, c)
		}
	} else {
		response.FailWithMessage("获取数据失败", c)
	}
}
